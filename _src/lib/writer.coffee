# # NsqWriter Module
# ### extends [Basic](basic.coffee.html)
#
# This module is a helper to simply write data to nsq

# **npm modules**
nsq = require 'nsqjs'

# **internal modules**
configurator = require("../configurator")


class NsqWriter extends require( "./basic" )
	
	# ## defaults
	defaults: =>
		_.extend super, 
			# **host** *String* Host of a nsqd
			host: "127.0.0.1"
			# **port** *Number* Port of a nsqd
			port: 4150

			# **deflate** *Boolean* Use zlib Deflate compression.
			deflate: false
			# **deflateLevel** *Number* Use zlib Deflate compression level.
			deflateLevel: 6
			# **clientId** *String|Null* An identifier used to disambiguate this client.
			clientId: null

	constructor: ->
		@connected = false

		super
		if not @config.active
			@log "warning", "nsq writer disabled"
			return

		@fetchClientId()

		@publish = @_waitUntil( @_publish, "connected" )
		return

	_initClient: =>
		if @client?
			return @client

		@client = new nsq.Writer( @config.host, @config.port )

		@client.on( nsq.Writer.READY, @onConnect )
		@client.on( nsq.Writer.CLOSED, @onDisconnect )

		@client.on nsq.Writer.ERROR, ( err )=>
			@log "error", "nsq error", err
			return

		return @client

	_publish: ( topic, data, cb )=>
		if not @config.active
			@_handleError( cb, "ENSQOFF" )
			return

		@log "debug", "publish", topic
		@client.publish topic, JSON.stringify(data), ( err )=>
			if err
				cb( err )
				return
			@log( "debug", "send data to `#{topic}`" )
			cb( null )
			return

		return




module.exports = new NsqWriter( configurator.getConfig( "nsq" ) )