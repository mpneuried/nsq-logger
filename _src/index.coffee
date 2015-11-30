exports.version = '@@version'

exports.

module.exports = ( config )->
	
	return 
		Writer: require './lib/writer'
		Reader: require './lib/reader'
		Basic: require './lib/basic'
		Logger: require './lib/main'
