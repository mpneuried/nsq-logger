# # NsqLogger Module
# ### extends [Basic](basic.coffee.html)
#
# A reader factory to spin up on reader per topic

# **npm modules**
_isArray = require( "lodash/isArray" )
_isFunction = require( "lodash/isFunction" )

# **internal modules**
Config = require "./config"
Topics = require 'nsq-topics'
Writer = require "./writer"
Reader = require "./reader"



class NsqLogger extends require( "./basic" )
	# ## defaults
	defaults: =>
		@extend super,
			# **loggerChannel** *String* The channel name for the logger to each topic
			loggerChannel: "actionlog"
			# **exceededTopic** *String* A topic name, that will store exceeded messages.
			exceededTopic: "_exceeded"
			# **ignoreTopics** *String[]|Function* A list of topics that should be ignored or a function that will called to check the ignored topics manually
			ignoreTopics: null
			# **namespace** *String* A namespace for the topics. This will be added/removed transparent to the topics. So only topics within this namespace a relevant.
			namespace: null

	constructor: ( options )->
		
		@READERS = {}
		
		# set flags
		@ready = false

		super( options )
		
		@debug "config", @config
				
		_writerInst = null
		@getter "Writer", =>
			if not _writerInst?
				_writerInst = new Writer( @config )
			return _writerInst

		_topicsInst = null
		@getter "Topics", =>
			if not _topicsInst?
				_topicsInst = new Topics( @config )
			return _topicsInst
			
		@_start()
		return

	_start: =>
		if @ready
			return
		if not @active()
			return
			
		@Topics.filter ( testT )=>
			if not @nsTest( testT )
				return false
				
			_tp = @nsRem( testT )
			
			if _tp is @config.exceededTopic
				return false
			
			if @config.ignoreTopics?
				if _isArray( @config.ignoreTopics ) and _tp in @config.ignoreTopics
					return false
				if _isFunction( @config.ignoreTopics )
					return @config.ignoreTopics( _tp )
					
			return true

		@Topics.list ( err, topics )=>
			if err
				@log "error", "initial topic read"
				# on initial read error retry to read the topic after 60 sec
				setTimeout( @read, 60 * 1000 )
				return
			# create initail readers
			for _tp in topics
				@addReader( _tp )

			# listen to topic changes
			@Topics.on "add", @addReader
			@Topics.on "remove", @removeReader

			@ready = true
			@connected = true
			@emit( "ready" )
			return
		
		
		return
	
	connect: =>
		if not @config.active
			return
		
		@Writer.connect()
		@Topics.activate()
		
		@_start()
		return @
	
	disconnect: =>		
		@connected = false
		@ready = false
		@Topics.deactivate()
		@Topics.removeListener( "add", @addReader )
		@Topics.removeListener( "remove", @addReader )
		@_destroyReaders =>
			@debug "disconnected"
			@emit( "disconnected" )
			return
		return
		
	destroy: ( cb )=>
		@warning "destroy logger"
		if not @ready
			@debug "not ready to destroy"
			cb()
			return
		
		@disconnect()
		
		@Writer.destroy =>
			@debug "writer destroyed"
			@_destroyReaders( cb )
			return
			
		return

	addReader: ( topic )=>
		topic = @nsRem( topic )
		if @READERS[ topic ]?
			@_handleError( "addReader", "EREADEREXISTS", { topic: topic } )
			return
		@READERS[ topic ] = new Reader( @, topic, @config.loggerChannel, @config )
		@READERS[ topic ].on "message", ( data, cb, msg )=>
			@emit( "message", topic, data, cb, msg )
			return

		@READERS[ topic ].on "exceeded", ( data, cb )=>
			@exceeded( topic, data, cb )
			return

		@READERS[ topic ].connect()

		@log "info", "reader ´#{topic}´ added"
		return

	removeReader: ( topic )=>
		topic = @nsRem( topic )
		if not @READERS[ topic ]?
			@_handleError( "removeReader", "EREADERNOTFOUND", { topic: topic } )
			return

		@READERS[ topic ].destroy ( err )=>
			if err
				@log "error", "destroy reader", err
				return
			@READERS[ topic ].removeAllListeners()
			delete @READERS[ topic ]
			@log "info", "reader ´#{topic}´ destroyed", Object.keys( @READERS )
			return
		return

	exceeded: ( topic, data )=>
		_data =
			topic: topic
			payload: data
		
		@emit( "exceeded", @nsRem( topic ), data )
		
		@Writer.connect()
		@Writer.publish @config.exceededTopic, _data , ( err )=>
			if err
				@log "error", "write messag to exceeded list", err
			return
		return
	
	_destroyReaders: ( cb )=>
		@warning "destroy #{_count} readers"
		_count = Object.keys( @READERS ).length
		
		for _name, _reader of @READERS
			@debug "destroy reader: " + _name
			@READERS[ _name ].destroy =>
				@debug "reader destryed: " + _name
				_count--
				if _count <= 0
					@removeAllListeners()
					cb()
				return
		return
		

	ERRORS: =>
		return @extend {}, super,
			# Exceptions
			"EREADEREXISTS": [ 409, "A reader for the topic `<%=topic%>` allready exists" ]
			"EREADERNOTFOUND": [ 404, "The reader for the topic `<%=topic%>` was not found" ]

module.exports = NsqLogger
