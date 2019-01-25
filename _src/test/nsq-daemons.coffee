spawn = require('child_process').spawn
fs = require( "fs" )
pathHelper = require( "path" )

_isArray = require('lodash/isArray')

_nsqDataPath = pathHelper.resolve( "./.nsqdata/" )

try
	fs.mkdirSync( _nsqDataPath )

LOOKUP_A_HOST = process.env.NSQ_LOOKUP_A_HOST || "0.0.0.0"
LOOKUP_B_HOST = process.env.NSQ_LOOKUP_B_HOST || "0.0.0.0"
NSQ_HOST = process.env.NSQ_HOST || "0.0.0.0"

daemons = [
	{
		"name": "LOOKUP-A"
		"bin": "nsqlookupd"
		"args": {
			"http-address": LOOKUP_A_HOST + ":4177"
			"tcp-address": LOOKUP_A_HOST + ":4176"
		}
	},{
		"name": "LOOKUP-B"
		"bin": "nsqlookupd"
		"args": {
			"http-address": LOOKUP_B_HOST + ":4179"
			"tcp-address": LOOKUP_B_HOST + ":4178"
		}
	},{
		"name": "NSQ"
		"bin": "nsqd"
		"args": {
			"http-address": NSQ_HOST + ":4157"
			"tcp-address": NSQ_HOST + ":4156"
			"lookupd-tcp-address": [ LOOKUP_A_HOST + ":4176", LOOKUP_B_HOST + ":4160" ]
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
		for daemon, idx in daemons
			@create( daemon, idx )

		setTimeout( cb, 1000 * idx )
		return
		
	lookupdAddresses: ( type="http" )=>
		_ret = []
		for daemon in daemons when daemon.bin is "nsqlookupd"
			_ret.push daemon.args?[ type + "-address" ]
		
		return _ret
		
	nsqdAddress: ( type="http" )=>
		for daemon in daemons when daemon.bin is "nsqd"
			return daemon.args?[ type + "-address" ]
		return null
		
	
	create: ( options, wait=0 )=>
		setTimeout( =>
			_args = []
			for _k, _v of options.args
				if _isArray( _v )
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
			daemon = spawn( "#{ @basepath }/#{options.bin}", _args )

			daemon.stdout.on "data", ( data )->
				console.log "LOG #{options.name}:", data.toString() if process.env.NSQLOG
				return
				
			daemon.stderr.on "data", ( data )->
				console.error "ERR #{options.name}:", data.toString() if process.env.NSQERR
				return

			daemon.on "close", ( data )=>
				console.log('data',data);
				
				console.log "⛔️  STOPPED #{options.name}", arguments
				@closedOne()
				return
			
			@running.push( daemon )
			@iRunning++
			return
		, 1000 * wait )
		return
	
	stop: ( cb )=>
		console.log "STOP daemons!"
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
	
