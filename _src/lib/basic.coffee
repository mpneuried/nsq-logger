# # NsqBasic Module
# ### extends [Basic](basic.coffee.html)
#
# a collection of shared nsq methods

# **npm modules**

# **internal modules**
utils = require( "../utils" )

class NsqBasic extends require( "../basic" )

	# ## defaults
	defaults: =>
		_.extend super,
			# **active** *Boolean* Configuration to (en/dis)abel the nsq recorder
			active: false

	constructor: ->
		@connected = false
		super
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

	connect: =>
		if not @config.active
			return

		@_initClient()

		if not @connected
			@disconnect = false
			@log "warning", "try to connect"
			@client.connect()
		return

	disconnect: =>
		@disconnect = true
		@client.close()
		return

	reconnect: =>
		# do not reconnect if it's a manual disconnect
		if @disconnect
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
		@log "warning", "connection lost"
		# if it's currently marked as connected start reconnecting
		if @connected
			@reconnect()
		@connected = false
		@emit( "disconnected" )
		return

	ERRORS: =>
		return _.extend {}, super,
			# Exceptions
			"ENSQOFF": "Nsq is currently disabled"
			"EINVALIDCLIENTID"; [ 406, "The given clientId option is invalid. It has to be a String or function returning a string" ]

module.exports = NsqBasic
