exports.version = '@@version'

config = require './lib/config'

module.exports = ( _cnf )->
	config.set( _cnf )
	
	return {
		config: config
		writer: require './lib/writer'
		topics: require './lib/topics'
		configure: ( cnf )->
			return config.set( _cnf )
		getReader: require './lib/reader'
		create: ->
			return require './lib/logger'
	}
