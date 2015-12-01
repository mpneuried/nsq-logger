should = require('should')
_ = require('lodash')

testData = require( "./data" )
utils = require( "./utils" )

testServers = require( "./nsq-deamons" )


CNF =
	clientId: "mochaTest"
	lookupdPollInterval: 1

NsqLogger = null

logger = null
writer = null



describe "----- nsq-logger TESTS -----", ->

	before ( done )->
		testServers.start ->
			NsqLogger = require( "../." )( CNF )
			
			logger = NsqLogger.create()
			writer = NsqLogger.writer
			writer.connect()
			done()
			return
		return

	after ( done )->
		@timeout( 10000 )
		testData.cleanup NsqLogger.config.lookupdHTTPAddresses, ->
			logger.destroy ->
				testServers.stop done
				return
		return

	describe 'Main Tests', ->
		it "wait for a single message", ( done )->
			@timeout( 10000 )
			_topic = testData.newTopic()
			_data = utils.randomString( 1024 )
			
			logger.on "message", ( topic, data, cb )->
				cb()
				# wait for the previously generated topic
				if topic is _topic
					topic.should.equal( _topic )
					data.should.equal( _data )
					
					done()
				return
			writer.publish( _topic, _data )
			return
			
		it "test many messages within multiple topics", ( done )->
			@timeout( 10000 )
			
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
			
		it "test many messages within multiple topics", ( done )->
			@timeout( 10000 )
			
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
			
		return
	return
