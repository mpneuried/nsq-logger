spawn = require('child_process').spawn
fs = require( "fs" )
pathHelper = require( "path" )

_ = require('lodash')

_nsqDataPath = pathHelper.resolve( "./.nsqdata/" )

try
	fs.mkdirSync( _nsqDataPath )

deamons = [
	{
		"name": "LOOKUP-A"
		"bin": "nsqlookupd"
		"args": {
			"http-address": "127.0.0.1:4161"
			"tcp-address": "127.0.0.1:4160"
		}
	},{
		"name": "LOOKUP-B"
		"bin": "nsqlookupd"
		"args": {
			"http-address": "127.0.0.1:4163"
			"tcp-address": "127.0.0.1:4162"
		}
	},{
		"name": "NSQ"
		"bin": "nsqd"
		"args": {
			"lookupd-tcp-address": [ "127.0.0.1:4160", "127.0.0.1:4162" ]
			"data-path": _nsqDataPath	
		}
	}
]

class Deamons extends require( "events" ).EventEmitter
	constructor: ->
		@iRunning = 0
		@running = []
		
		@basepath = pathHelper.resolve( "./node_modules/nsq-bundle/bin/" )
		return
	
	closedOne: =>
		@iRunning--
		@emit "close"
		if @iRunning <= 0
			@emit "closedAll"
		return
	
	start: ( cb )=>
		for deamon in deamons
			@running.push( @create( deamon, @closedOne ) )
			@iRunning++
		
		setTimeout( cb, 1000 )
		return
	
	create: ( options, closed )->
		_args = []
		for _k, _v of options.args
			if _.isArray( _v )
				for _vs in _v
					_arg = "-" + _k
					if _vs?
						_arg += "=" + _vs
					_args.push _arg
			else
				_arg = "-" + _k
				if _v?
					_arg += "=" + _v
				_args.push _arg
		
		if process.env.NSQLOG
			console.log "✅  START #{ @basepath }/#{options.bin} #{_args.join( " " )}" if process.env.NSQLOG
		else
			console.log "✅  START #{options.name}"
		deamon = spawn( "#{ @basepath }/#{options.bin}", _args )

		deamon.stdout.on "data", ( data )->
			console.log "LOG #{options.name}:", data.toString() if process.env.NSQLOG
			return
			
		deamon.stderr.on "data", ( data )->
			console.error "ERR #{options.name}:", data.toString() if process.env.NSQERR
			return

		deamon.on "close", ( data )->
			console.log "⛔️  STOPPED #{options.name}"
			closed()
			return
		
		return deamon
	
	stop: ( cb )=>
		console.log "STOP deamons!"
		if @iRunning <= 0
			cb()
			return
		
		for rd in @running
			rd.kill()
		
		@on "closedAll", ->
			cb()
			return
		return

module.exports = new Deamons()
	
