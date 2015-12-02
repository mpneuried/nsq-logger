# # NsqLogger Module
# ### extends [Basic](basic.coffee.html)
#
# A reader factory to spin up on reader per topic

# **npm modules**
_ = require( "lodash" )

# **internal modules**
Config = require "./config"
Topics = require 'nsq-topics'
Writer = require "./writer"
Reader = require "./reader"

READERS = {}

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

	constructor: ( options )->
		# set flags
		@ready = false

		super( options )

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

		# add a topic filter to only connect to topics that do not start with a "_"
		@Topics.filter ( testT )=>
			if testT is @config.exceededTopic
				return false
			if not @config.ignoreTopics?
				return true
			if _.isArray( @config.ignoreTopics ) and testT in @config.ignoreTopics
				return false
			if _.isFunction( @config.ignoreTopics )
				return @config.ignoreTopics( testT )
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
			@emit( "ready" )
			return
		return
		
	destroy: ( cb )=>
		@warning "destroy logger"
		if not @ready
			return
		
		_count = Object.keys( READERS ).length
		
		@Writer.destroy =>
			@warning "destroy #{_count} readers"
			for _name, _reader of READERS
				READERS[ _name ].destroy =>
					_count--
					if _count <= 0
						@removeAllListeners()
						cb()
					return
			return
			
		return

	addReader: ( topic )=>
		if READERS[ topic ]?
			@_handleError( "addReader", "EREADEREXISTS", { topic: topic } )
			return
		READERS[ topic ] = new Reader( @, topic, @config.loggerChannel, @config )
		READERS[ topic ].on "message", ( data, cb )=>
			@message( topic, data, cb )
			return

		READERS[ topic ].on "exceeded", @exceeded

		READERS[ topic ].connect()

		@log "info", "reader ´#{topic}´ added"
		return

	removeReader: ( topic )=>
		if not READERS[ topic ]?
			@_handleError( "removeReader", "EREADERNOTFOUND", { topic: topic } )
			return

		READERS[ topic ].destroy ( err )=>
			if err
				@log "error", "destroy reader", err
				return
			READERS[ topic ].removeAllListeners()
			delete READERS[ topic ]
			@log "info", "reader ´#{topic}´ destroyed", Object.keys( READERS )
			return
		return

	message: ( topic, data, cb )=>
		@emit( "message", topic, data, cb )
		return

	exceeded: ( topic, data )=>
		_data =
			topic: topic
			payload: data

		@Writer.connect()
		@Writer.publish @config.exceededTopic, _data , ( err )=>
			if err
				@log "error", "write messag to exceeded list", err
			return
		return

	ERRORS: =>
		return @extend {}, super,
			# Exceptions
			"EREADEREXISTS": [ 409, "A reader for the topic `{{topic}}` allready exists" ]
			"EREADERNOTFOUND": [ 404, "The reader for the topic `{{topic}}` was not found" ]

module.exports = NsqLogger
