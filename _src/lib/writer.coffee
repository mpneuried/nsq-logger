# # NsqWriter Module
# ### extends [Basic](basic.coffee.html)
#
# This module is a helper to simply write data to nsq

# **npm modules**
nsq = require 'nsqjs'

# **internal modules**

class NsqWriter extends require( "./basic" )
	
	# ## defaults
	defaults: =>
		@extend super,
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
		
		@publish = @_waitUntil( @_publish, "connected" )
		
		if not @config.active
			@warning "nsq writer disabled"
			return
		
		@fetchClientId()
		return

	_initClient: =>
		if @client?
			return @client

		@client = new nsq.Writer( @config.host, @config.port )

		@client.on( nsq.Writer.READY, @onConnect )
		@client.on( nsq.Writer.CLOSED, @onDisconnect )

		@client.on nsq.Writer.ERROR, ( err )=>
			@error "nsq error", err
			return
		
		@debug "init writer client", @client
		return @client

	_publish: ( topic, data, cb )=>
		if not @config.active
			@_handleError( cb, "ENSQOFF" )
			return

		@debug "publish", topic
		@client.publish topic, JSON.stringify(data), ( err )=>
			if err
				if cb?
					cb( err )
				else
					@error( "publish to topic `#{topic}`", err )
				return
			@debug "send data to `#{topic}`"
			cb( null ) if cb?
			return

		return

module.exports = new NsqWriter()
