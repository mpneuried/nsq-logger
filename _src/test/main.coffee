should = require('should')
extend = require( "extend" )
_compact = require( "lodash/compact" )
_isEmpty = require( "lodash/isEmpty" )

config = require( "../config" )

randoms = require( "randoms" )

testServers = require( "./nsq-daemons" )
NsqLogger = require( "../." )

[ nsqdHost, nsqdPort ] = testServers.nsqdAddress( "tcp" )?.split( ":" )
NO_DEAMONS = if process.env.NO_DEAMONS then true else false
console.log('NO_DEAMONS',NO_DEAMONS, process.env.NO_DEAMONS);

CNF =
	clientId: "mochaTest"
	lookupdPollInterval: 1
	logging: {
		severity: "warning"
	}
	host: nsqdHost
	port: parseInt( nsqdPort, 10 )
	lookupdHTTPAddresses: testServers.lookupdAddresses( "http" )
	lookupdTCPAddresses: testServers.lookupdAddresses( "tcp" )
	namespace: null

logger = null
writer = null
config = null


namespaces = [ null, "mochatestA_", "mochatestB_" ]


describe "----- nsq-logger TESTS -----", ->
	
	before ( done )->
		if NO_DEAMONS
			done()
			return
		
		@timeout( 10000 )
		testServers.start ->
			done()
			return
		return
	
	after ( done )->
		if NO_DEAMONS
			done()
			return
		testServers.stop( done )
		return
	
	namespaces.forEach ( namespace )->
		
		testData = require( "./data" )( namespace )
		
		describe "Namespace `#{namespace}` Tests", ->
			
			before ( done )->
				logger = new NsqLogger( extend( {}, CNF, {namespace: namespace} ) )

				writer = logger.Writer
				config = logger.config
				writer.connect()
				done()
				return
			
			after ( done )->
				@timeout( 20000 )
				hosts = testServers.lookupdAddresses( "http" )
				console.log('          cleanup hosts ...',hosts )
				testData.cleanup hosts, ->
					logger.destroy ->
						console.log('logger destroy done' )
						done()
						return
				return

			describe 'Main Tests', ->
				it "wait for a single message", ( done )->
					@timeout( 10000 )
					_topic = testData.newTopic()
					_data = randoms.obj.string( 13, 666 )
					
					logger.on "message", ( topic, data, cb, msg )->
						cb()
						
						# wait for the previously generated topic
						if topic is _topic
							msg.attempts.should.be.Number().equal( 1 )
							
							topic.should.equal( _topic )
							data.should.eql( _data )
							
							logger.removeAllListeners( "message" )
							done()
						return
					writer.publish( _topic, _data )
					return
					
				it "test many messages within multiple topics", ( done )->
					@timeout( 15000 )
					
					logger.removeAllListeners( "message" )
					
					_topics = {}
					for idx in [1..5]
						_topic = testData.newTopic()
						_topics[ _topic ] = []
						for idx in [1..20]
							_topics[ _topic ].push JSON.stringify( randoms.obj.string( 3, 42 ) )
				
					logger.on "message", ( topic, data, cb )->
						cb()
						# wait for the previously generated topic
						if _topics[topic]?
							_idx = _topics[topic].indexOf( JSON.stringify( data ) )
							_topics[topic][ _idx ] = null
							
							if not _compact( _topics[topic] ).length
								delete _topics[topic]
							
							if not _topics? or _isEmpty( _topics )
								logger.removeAllListeners( "message" )
								done()
						return
					
					for tpc, datas of _topics
						for data in datas
							writer.publish( tpc, JSON.parse( data ) )
					return
					
				it "test many json messages within multiple topics", ( done )->
					@timeout( 6000 )
					
					logger.removeAllListeners( "message" )
					
					_topics = {}
					for idx in [1..5]
						_topic = testData.newTopic()
						_topics[ _topic ] = []
						for idx in [1..5]
							_topics[ _topic ].push JSON.stringify( randoms.obj.string.lower( 13, 666 ) )
				
					logger.on "message", ( topic, data, cb )->
						cb()
						# wait for the previously generated topic
						if _topics[topic]?
							# use stringified versions to find it within the list
							_idx = _topics[topic].indexOf( JSON.stringify( data ) )
							_topics[topic][ _idx ] = null
							
							if not _compact( _topics[topic] ).length
								delete _topics[topic]
								
							if not _topics? or _isEmpty( _topics )
								logger.removeAllListeners( "message" )
								done()
						return
					for tpc, datas of _topics
						for data in datas
							writer.publish( tpc, JSON.parse( data ) )
					return
					
				return
			return
		return
		
	
	describe "Active Tests", ->
		
		logger2 = null
		
		it "wait for errors of deactivated logger", ( done )->
			@timeout(4000)
			logger2 = new NsqLogger( extend( {}, CNF, { active: false} ) )
			
			logger2.on "error", ( err )->
				throw err
				return
				
			setTimeout( done, 3000 )
			return
		
		it "activate logger", ( done )->
			
			@timeout( 10000 )
			_topic = "nsq_logger_test_activate_test"
			_data = randoms.obj.string( 13, 666 )
			
			logger2.on "message", ( topic, data, cb, msg )->
				cb()
				# wait for the previously generated topic
				if topic is _topic
					msg.attempts.should.be.Number().equal( 1 )
					
					topic.should.equal( _topic )
					data.should.eql( _data )
					
					logger.removeAllListeners( "message" )
					done()
				return
				
			logger2.on "ready", ->
				logger2.Writer.publish( _topic, _data )
				return
				
			logger2.activate()
			
			return
		
		return
		
	return