utils =
	randomString: ( string_length = 5, specialLevel = 0 ) ->
		chars = "BCDFGHJKLMNPQRSTVWXYZbcdfghjklmnpqrstvwxyz"
		chars += "0123456789" if specialLevel >= 1
		chars += "_-@:." if specialLevel >= 2
		chars += "!\"§$%&/()=?*'_:;,.-#+¬”#£ﬁ^\\˜·¯˙˚«∑€®†Ω¨⁄øπ•‘æœ@∆ºª©ƒ∂‚å–…∞µ~∫√ç≈¥" if specialLevel >= 3

		randomstring = ""
		i = 0
		
		while i < string_length
			rnum = Math.floor(Math.random() * chars.length)
			randomstring += chars.substring(rnum, rnum + 1)
			i++
		randomstring
	
	randRange: ( lowVal, highVal )->
		Math.floor( Math.random()*(highVal-lowVal+1 ))+lowVal
	
	clone: (inp)->
		return JSON.parse(JSON.stringify(inp))
	
	randomobj: ( opt = {}, depth = 0 )->
		tgrt={}
		for i in [0..utils.randRange(1,( if opt.maxObjSize? then  opt.maxObjSize else 13 ))]
			_key = utils.randomString( utils.randRange(2,32),0 )
			if not tgrt[ _key ]?
				tgrt[ _key ] = utils.randomdata( opt, depth )
		return tgrt

	randomdata: ( opt = {} , depth = 0 )->
		if depth >= ( if opt.maxDepth? then opt.maxDepth else 2 )
			_i = utils.randRange(1,2)
		else
			_i = utils.randRange(1,4)
			
		_depth = depth + 1
		switch _i
			when 1
				return utils.randomString( utils.randRange(1,( if opt.maxStringLength? then opt.maxStringLength else 1024*5 )), ( if opt.maxComplex? then opt.maxComplex else 3 ) )
			when 2
				return utils.randRange(1,1024*64 )
			when 3
				_arr = []
				for i in [0..utils.randRange(0,13)]
					_arr.push utils.randomdata( opt, _depth )
				return _arr
			when 4
				return utils.randomobj( opt, _depth )

module.exports = utils
