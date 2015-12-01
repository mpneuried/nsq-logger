# # NsqTopics Wrapper
# ### uses [NsqTopics](https://github.com/mpneuried/nsq-topics)
#
# Create and configute a nsq-topics instance

# **npm modules**
NsqTopics = require 'nsq-topics'

# **internal modules**
config = require( "./config" )

module.exports = new NsqTopics( config )
