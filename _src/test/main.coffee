should = require('should')
_ = require('lodash')

config = require( "../config" )

utils = require( "./utils" )

testServers = require( "./nsq-deamons" )
NsqLogger = require( "../." )

CNF =
	clientId: "mochaTest"
	lookupdPollInterval: 1
	logging: {}
	lookupdHTTPAddresses: [ "localhost:4161", "localhost:4163" ]
	namespace: null


logger = null
writer = null
config = null


namespaces = [ null, "mochatestA_", "mochatestB_" ]


describe "----- nsq-logger TESTS -----", ->
	
	before ( done )->
		testServers.start ->
			done()
			return
		return
	
	after: ( done )->
		testServers.stop( done )
		return
	
	namespaces.forEach ( namespace )->
		
		testData = require( "./data" )( namespace )
		
		describe "Namespace `#{namespace}` Tests", ->
			
			before ( done )->
				logger = new NsqLogger( _.extend( {}, CNF, {namespace: namespace} ) )

				writer = logger.Writer
				config = logger.config
				writer.connect()
				done()
				return

			after ( done )->
				@timeout( 10000 )
				testData.cleanup config.lookupdHTTPAddresses, ->
					logger.destroy ->
						done()
						return
				return

			describe 'Main Tests', ->
				it "wait for a single message", ( done )->
					@timeout( 10000 )
					_topic = testData.newTopic()
					_data = utils.randomString( 1024 )
					
					logger.on "message", ( topic, data, cb, msg )->
						cb()
						
						# wait for the previously generated topic
						if topic is _topic
							msg.attempts.should.be.Number().equal( 1 )
							
							topic.should.equal( _topic )
							data.should.equal( _data )
							
							logger.removeAllListeners( "message" )
							done()
						return
					writer.publish( _topic, _data )
					return
					
				it "test many messages within multiple topics", ( done )->
					@timeout( 6000 )
					
					logger.removeAllListeners( "message" )
					
					_topics = {}
					for idx in [1..5]
						_topic = testData.newTopic()
						_topics[ _topic ] = []
						for idx in [1..20]
							_topics[ _topic ].push utils.randomString( utils.randRange( 1, 20 ) * 1024 )
				
					logger.on "message", ( topic, data, cb )->
						cb()
						# wait for the previously generated topic
						if _topics[topic]?
							_idx = _topics[topic].indexOf( data )
							_topics[topic][ _idx ] = null
							
							if not _.compact( _topics[topic] ).length
								delete _topics[topic]
								
							if not _topics? or _.isEmpty( _topics )
								logger.removeAllListeners( "message" )
								done()
						return
					
					for tpc, datas of _topics
						for data in datas
							writer.publish( tpc, data )
					return
					
				it "test many json messages within multiple topics", ( done )->
					@timeout( 6000 )
					
					logger.removeAllListeners( "message" )
					
					_topics = {}
					for idx in [1..5]
						_topic = testData.newTopic()
						_topics[ _topic ] = []
						for idx in [1..5]
							_topics[ _topic ].push JSON.stringify( utils.randomobj( { maxObjSize: 5, maxDepth: 1, maxComplex: 1, maxStringLength: 50 } ) )
				
					logger.on "message", ( topic, data, cb )->
						cb()
						# wait for the previously generated topic
						if _topics[topic]?
							# use stringified versions to find it within the list
							_idx = _topics[topic].indexOf( JSON.stringify( data ) )
							_topics[topic][ _idx ] = null
							
							if not _.compact( _topics[topic] ).length
								delete _topics[topic]
								
							if not _topics? or _.isEmpty( _topics )
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
	return
