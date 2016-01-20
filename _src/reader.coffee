# # NsqReader Module
# ### extends [Basic](basic.coffee.html)
#
# a nsq reader for a single topic

# **npm modules**
nsq = require 'nsqjs'

# **internal modules**
config = require( "./config" )

class NsqReader extends require( "./basic" )

	# ## defaults
	defaults: =>
		@extend super,
			# **maxInFlight** *Number* The maximum number of messages to process at once. This value is shared between nsqd connections. It's highly recommended that this value is greater than the number of nsqd connections.
			maxInFlight: 1
			# **heartbeatInterval** *Number* The frequency in seconds at which the nsqd will send heartbeats to this Reader.
			heartbeatInterval: 30
			# **lookupdTCPAddresses** *String[]* A list of nsq lookup servers
			lookupdTCPAddresses: [ "127.0.0.1:4160", "127.0.0.1:4162" ]
			# **lookupdHTTPAddresses** *String[]* A list of nsq lookup servers
			lookupdHTTPAddresses: [ "127.0.0.1:4161", "127.0.0.1:4163" ]
			# **maxAttempts** *Number* The number of times to a message can be requeued before it will be handed to the DISCARD handler and then automatically finished. 0 means that there is no limit. If not DISCARD handler is specified and maxAttempts > 0, then the message will be finished automatically when the number attempts has been exhausted.
			maxAttempts: 10
			# **messageTimeout** *Number|Null* Message timeout in ms or `null` for no timeout
			messageTimeout: null
			# **sampleRate** *Number|Null* Deliver a percentage of all messages received to this connection. 1 <= sampleRate <= 99
			sampleRate: null
			# **clientId** *String|Null* An identifier used to disambiguate this client.
			clientId: null

			# **requeueDelay** *Number|Null* The delay is in seconds. This is how long nsqd will hold on the message before attempting it again.
			requeueDelay: 5
			# **namespace** *String* A namespace for the topics. This will be added/removed transparent to the topics. So only topics within this namespace a relevant.
			namespace: null
			
	constructor: ( @logger, @topic, @channel, options )->
		@connected = false
		
		super( options )
		
		@fetchClientId()
		return

	_initClient: =>
		if @client
			return @client
		@debug "start reader", @topic, @channel, @config.namespace
		@client = new nsq.Reader( @nsAdd( @topic ), @channel, @config )

		@client.on( nsq.Reader.NSQD_CLOSED, @onDisconnect )
		@client.on( nsq.Reader.NSQD_CONNECTED, @onConnect )
		@client.on( nsq.Reader.MESSAGE, @onMessage )
		
		@client.on( nsq.Reader.DISCARD, @onDiscard )
		@client.on( nsq.Reader.ERROR, @onError )

		return @client

	onError: ( err )=>
		@error "nsq-reader", err
		return

	onDiscard: ( msg )=>
		@emit( "exceeded", msg.json() )
		@warning "message exceeded", @topic, msg.json()
		return

	onMessage: ( msg )=>
		@emit( "message", msg.json(), ( err )=>
			if err
				@error "message processing", err
				msg.requeue( @config.requeueDelay )
				return
			msg.finish()
			return
		, msg )
		return


module.exports = NsqReader
