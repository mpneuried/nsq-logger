should = require('should')
_ = require('lodash')

NsqLogger = require( "../." )
nsqLogger = null

CNF =
	lookupdHTTPAddresses: []
	lookupdPollInterval: 5
	topicFilter: null

describe "----- nsq-logger TESTS -----", ->

	before ( done )->
		nsqLogger = new NsqTopics( CNF )
		
		done()
		return

	after ( done )->
		done()
		return

	describe 'Main Tests', ->

		# Implement tests cases here
		it "initial value", ( done )->
			# TODO
			done()
			return			
		return
	return



	
