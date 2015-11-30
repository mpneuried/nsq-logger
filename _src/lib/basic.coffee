# # NsqBasic Module
# ### extends [Basic](basic.coffee.html)
#
# a collection of shared nsq methods

# **npm modules**

# **internal modules**
utils = require( "../utils" )
configurator = require("../configurator")

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
		if @config.clientId?
			return @config.clientId

		_ip = utils.getIP( ( if configurator.get( "identifyByIpV6" ) then "IPv6" else "IPv4" ), false )
		_version = configurator.get( "server_care" ).version.replace( /\./g, "_" )
		switch root._milon_servertype
			when "admin"
				_severname = "studio"
			else
				_severname = root._milon_servertype
		@config.clientId = _version + ":" + _severname + ":" + _ip

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

module.exports = NsqBasic