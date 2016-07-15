module.exports = (grunt) ->
	# Project configuration.
	grunt.initConfig
		pkg: grunt.file.readJSON('package.json')
		watch:
			module:
				files: ["_src/**/*.coffee"]
				tasks: [ "coffee:base" ]
			
		coffee:
			base:
				expand: true
				cwd: '_src',
				src: ["**/*.coffee"]
				dest: ''
				ext: '.js'
		
		usebanner:
			options:
				position: "top"
				banner: """
/*
 * nsq-logger <%= pkg.version %> ( <%= grunt.template.today( 'yyyy-mm-dd' )%> )
 * http://mpneuried.github.io/nsq-logger/
 *
 * Released under the MIT license
 * https://github.com/mpneuried/nsq-logger/blob/master/LICENSE
*/
"""			
			js:
				files:
					src: [ "*.js", "test/*.js" ]
		clean:
			base:
				src: [ "lib", "test" ]

			nsq:
				src: [ ".nsqdata/" ]

		includereplace:
			pckg:
				options:
					globals:
						version: "<%=pkg.version%>"

					prefix: "@@"
					suffix: ''

				files:
					"index.js": ["index.js"]

		
		mochacli:
			options:
				require: [ "should" ]
				reporter: "spec"
				bail: process.env.BAIL or false
				grep: process.env.GREP
				timeout: 3000
				slow: 3

			main:
				src: [ "test/main.js" ]
				options:
					env:
						#NSQERR: true
						severity_nsq_logger: process.env.SEVERITY or "error"

	# Load npm modules
	grunt.loadNpmTasks "grunt-contrib-watch"
	grunt.loadNpmTasks "grunt-contrib-coffee"
	grunt.loadNpmTasks "grunt-contrib-clean"
	grunt.loadNpmTasks "grunt-mocha-cli"
	grunt.loadNpmTasks "grunt-include-replace"
	grunt.loadNpmTasks "grunt-banner"

	# ALIAS TASKS
	grunt.registerTask "default", "build"
	grunt.registerTask "clear", [ "clean:base", "clean:nsq"  ]
	grunt.registerTask "test", [ "mochacli:main", "clean:nsq" ]

	grunt.registerTask "w", "watch"
	grunt.registerTask "b", "build"
	grunt.registerTask "t", "test"

	# build the project
	grunt.registerTask "build", [ "clear", "coffee:base", "includereplace", "usebanner:js" ]
	grunt.registerTask "build-dev", [ "clear", "coffee:base", "test" ]
