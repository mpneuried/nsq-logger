async = require('async')
hyperrequest = require('hyperrequest')

utils = require('./utils')


module.exports = ( namespace )->
	
	generatedTopics = []
	
	deleteTopic = ( host, topic )->
		return ( cb )->
			hyperrequest { url: "http://#{host}/delete_topic", qs: { topic: ( namespace or "" ) + topic } }, ( err, resp )->
				if resp?.statusCode is 200
					cb( null, topic )
				else
					cb( resp.body )
				return
			return
		
	deleteTopics = ( topics, hosts, cb )->
		if not topics?.length
			cb()
			return
		aFns = []
		for host in hosts
			for topic in topics
				aFns.push( deleteTopic( host, topic) )
			
		console.log "          delete #{topics.length} test topics ... "
		async.parallelLimit aFns, 5, ( errs, topics )->
			console.log "          ... done!"
			cb()
			return
		return
	return {
		newTopic: ->
			_t = utils.randomString( 5 )
			generatedTopics.push( _t )
			return _t
			
		cleanup: ( hosts, cb )->
			
			deleteTopics( generatedTopics, hosts, cb )
			
			return
	}
