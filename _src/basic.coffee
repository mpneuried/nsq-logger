# # NsqBasic Module
# ### extends [Basic](basic.coffee.html)
#
# a collection of shared nsq methods

# **npm modules**
_ = require( "lodash" )

# **internal modules**
Config = require "./config"

class NsqBasic extends require( "mpbasic" )()

	constructor: ( options )->
		@connected = false

		@on "_log", @_log

		@getter "classname", ->
			return @constructor.name.toLowerCase()

		# extend the internal config
		if options instanceof Config
			@config = options
		else
			@config = new Config( options )

		if not @config.active
			@log "warning", "disabled"
			return

		# init errors
		@_initErrors()

		@initialize( options )

		@debug "loaded"
		return

	fetchClientId: =>
		if _.isFunction( @config.clientId )
			_cid = @config.clientId()
			if not _.isString( @config.clientId )
				@_handleError( null, "EINVALIDCLIENTID" )
				return
				
			@config.clientId = _cid
			return @config.clientId
		
		if _.isString( @config.clientId )
			return @config.clientId
		
		@_handleError( null, "EINVALIDCLIENTID" )
		return @config.clientId


	active: =>
		return @config.active
			
	activate: =>
		if @config.active
			return false
		@config.active = true
		@connect()
		return true
	
	deactivate: =>
		if not @config.active
			return false
		@config.active = false
		@disconnect()
		return true

	connect: =>
		if not @config.active
			return

		@_initClient()

		if not @connected
			@disconnecting = false
			@log "info", "try to connect"
			@client.connect()
		return @

	disconnect: =>
		@disconnecting = true
		@client.close()
		return

	reconnect: =>
		# do not reconnect if it's a manual disconnect
		if @disconnecting
			return
		# try a reconnect every 5 sec until the client is online again
		@t_reconnect = setTimeout( =>
			@connect()
			if not @connected
				@reconnect()
			return
		, 5000 )
		return

	onConnect: =>
		@log "debug", "connection established"
		if @t_reconnect?
			clearTimeout(@t_reconnect)

		@connected = true
		@emit( "connected" )
		return

	onDisconnect: =>
		@log "warning", "connection lost" if not @disconnecting
		# if it's currently marked as connected start reconnecting
		if @connected and not @disconnecting
			@reconnect()
		@connected = false
		@emit( "disconnected" )
		return
	

	destroy: ( cb )=>
		if @connected
			@disconnect()
			@on "disconnected", ->
				@removeAllListeners()
				cb()
				return
			return
		cb()
		return
		
	nsTest: ( topic )=>
		if not @config.namespace?
			return true
		return topic[...@config.namespace.length] is @config.namespace
		
	nsRem: ( topic )=>
		if not @config.namespace?
			return topic
		if not @nsTest( topic )
			return topic
		return topic[@config.namespace.length..]
			
	nsAdd: ( topic )=>
		if not @config.namespace?
			return topic
		if @nsTest( topic )
			return topic
		return @config.namespace + topic
			
		
	ERRORS: =>
		return @extend {}, super,
			# Exceptions
			"ENSQOFF": [ 500, "Nsq is currently disabled"]
			"EINVALIDCLIENTID": [ 406, "The given clientId option is invalid. It has to be a String or function returning a string" ]

module.exports = NsqBasic
