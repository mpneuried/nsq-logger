# # NsqLogger Module
# ### extends [Basic](basic.coffee.html)
#
# A reader factory to spin up on reader per topic

# **npm modules**

# **internal modules**
configurator = require("../configurator")
Topics = require "./topics"
Reader = require "./reader"
Writer = require( "./writer" )
utils = require( "../utils" )

READERS = {}

class NsqLogger extends require( "./basic" )
	# ## defaults
	defaults: =>
		_.extend super,
			# **loggerChannel** *String* The channel name for the logger to each topic
			loggerChannel: "actionlog"

	constructor: ( options )->
		@ready = false

		super( options )
		if not @config.active
			@log "warning", "nsq reader disabled"
			return

		@start()
		return

	start: =>
		if @ready
			return

		# add a topic filter to only connect to topics that do not start with a "_"
		Topics.filter ( testT )=>
			if testT[0] is "_"
				return false
			return true

		Topics.list ( err, topics )=>
			if err
				@log "error", "initial topic read"
				# on initial read error retry to read the topic after 60 sec
				setTimeout( @read, 60 * 1000 )
				return

			# create initail readers
			for _tp in topics
				@addReader( _tp )

			# listen to topic changes
			Topics.on "add", @addReader
			Topics.on "remove", @removeReader

			@ready = false
			@emit( "ready" )
			return
		return

	addReader: ( topic )=>
		if READERS[ topic ]?
			@_handleError( "addReader", "EREADEREXISTS", { topic: topic } )
			return
		READERS[ topic ] = new Reader( @, topic, @config.loggerChannel )
		READERS[ topic ].on "message", @message
		READERS[ topic ].on "exceeded", @exceeded
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
		console.log "MESSGAGE", topic, data
		# TODO write log
		cb()
		return

	exceeded: ( topic, data )=>
		_data = 
			topic: topic
			payload: data

		Writer.connect()
		Writer.publish "_exceeded", _data , ( err )=>
			if err
				@log "error", "write messag to exceeded list", err
			return 
		return

	ERRORS: =>
		return _.extend {}, super,
			# Exceptions
			"EREADEREXISTS": "A reader for the topic `{{topic}}` allready exists"
			"EREADERNOTFOUND": "The reader for the topic `{{topic}}` was not found"


module.exports = new NsqLogger( configurator.getConfig( "nsq" ) )
