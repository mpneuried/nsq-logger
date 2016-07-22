# # NsqWriter Module
# ### extends [Basic](basic.coffee.html)
#
# This module is a helper to simply write data to nsq

# **npm modules**
nsq = require 'nsqjs'
_isString = require ( "lodash/isString" )

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
			# **namespace** *String* A namespace for the topics. This will be added/removed transparent to the topics. So only topics within this namespace a relevant.
			namespace: null

	constructor: ( options )->
		@connected = false
		super( options )
		
		@publish = @_waitUntil( @_publish, "connected" )
		
		if not @config.active
			@warning "nsq writer disabled"
			return
		
		@fetchClientId()
		return

	_initClient: =>
		if @client?
			return @client
		
		@client = new nsq.Writer( @config.host, @config.port, @config )

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

		@debug "publish", topic, @nsAdd( topic )
		if _isString( data )
			_data = data
		else
			_data = JSON.stringify(data)

		@client.publish @nsAdd( topic ), _data, ( err )=>
			if err
				if cb?
					cb( err )
				else
					@error( "publish to topic `#{topic}`", err )
				return
			@debug "send data to `#{topic}`"
			cb( null ) if cb?
			return

		return @

module.exports = NsqWriter
