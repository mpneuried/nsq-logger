# # Config Module
#
# a collection of shared nsq methods

# **npm modules**
_ = require( "lodash" )
extend = require( "extend" )

# **internal modules**

DEFAULTS =
	# **GENERAL**
	# **active** *Boolean* Configuration to (en/dis)abel the nsq recorder
	active: true
	# **clientId** *String|Null* An identifier used to disambiguate this client.
	clientId: null
	# **namespace** *String* A namespace for the topics. This will be added/removed transparent to the topics. So only topics within this namespace a relevant.
	namespace: null
	
	# **LOGGER**
	# **loggerChannel** *String* The channel name for the logger to each topic
	loggerChannel: "nsqlogger"
	# **exceededTopic** *String* A topic name, that will store exceeded messages.
	exceededTopic: "_exceeded"
	# **ignoreTopics** *String[]|Function* A list of topics that should be ignored or a function that will called to check the ignored topics manually
	ignoreTopics: null

	# **lookupdHTTPAddresses** *Number* Time in seconds to poll the nsqlookupd servers to sync the availible topics
	lookupdPollInterval: 60
	
	# **READER**
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
	# **requeueDelay** *Number|Null* The delay is in seconds. This is how long nsqd will hold on the message before attempting it again.
	requeueDelay: 5
	
	# **WRITER**
	# **host** *String* Host of a nsqd
	host: "127.0.0.1"
	# **port** *Number* Port of a nsqd
	port: 4150
	# **deflate** *Boolean* Use zlib Deflate compression.
	deflate: false
	# **deflateLevel** *Number* Use zlib Deflate compression level.
	deflateLevel: 6

	logging:
		severity: process.env[ "severity" ] or process.env[ "severity_nsq_logger"] or "warning"
		severitys: "fatal,error,warning,info,debug".split( "," )

addGetter = ( prop, _get, context )=>
	_obj =
		enumerable: true
		writable: true

	if _.isFunction( _get )
		_obj.get = _get
	else
		_obj.value = _get
	Object.defineProperty( context, prop, _obj )
	return

class Config
	
	constructor: ( input )->
		for _k, _v of DEFAULTS
			addGetter( _k, _v, @ )
			
		@set( input )
		return
		
	set: ( key, value )=>
		if not key?
			return
		if _.isObject( key )
			for _k, _v of key
				@set( _k, _v )
			return
		if _.isObject( @[ key ] ) and _.isObject( value ) and not _.isArray( value )
			@[ key ] = extend( true, {}, @[ key ], value )
		else
			@[ key ] = value
		return

module.exports = Config
