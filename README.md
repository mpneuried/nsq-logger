nsq-logger
============

[![Build Status](https://secure.travis-ci.org/mpneuried/nsq-logger.png?branch=master)](http://travis-ci.org/mpneuried/nsq-logger)
[![Build Status](https://david-dm.org/mpneuried/nsq-logger.png)](https://david-dm.org/mpneuried/nsq-logger)
[![NPM version](https://badge.fury.io/js/nsq-logger.png)](http://badge.fury.io/js/nsq-logger)

Nsq service to read messages from all topics listed within a list of nsqlookupd services.|

[![NPM](https://nodei.co/npm/nsq-logger.png?downloads=true&stars=true)](https://nodei.co/npm/nsq-logger/)

**INFO: all examples are written in coffee-script**

## Install

```
  npm install nsq-logger
```

## Initialize

```js
var logger = new NsqLogger( config );
```

**Example:**

```js
var NsqLogger = require( "nsq-logger" );

var config = {
    clientId: "myFooClient"
};

// create the logger
var logger = new NsqLogger( config );

// create a writer instance
/*
var NsqWriter = require( "nsq-logger/writer" );
var writer = new NsqLogger( config );
*/
// or just grab the one used inside the logger
var writer = logger.Writer;

logger.on( "message", function( topic, data, done ){
    // process your topic
    // Example response: -> topic="topic23" data ="Do some Stuff!"
    
    // mark message as done
    done();
});

writer.connect();
writer.publish( "topic23", "Do some Stuff!" );
```



**Config** 

<a name="config"></a>

- **clientId** : *( `String|Null` required )* An identifier used to disambiguate this client.
- **active** : *( `Boolean` default=true )* Configuration to (en/dis)abel the nsq recorder
- **namespace** : *( `String|Null` default=null )* Internally prefix the nsq topics. This will be handled transparent, but with this it's possible to separate different environments from each other. E.g. you can run a "staging" and "live" environment on one nsq cluster.
- **loggerChannel** : *( `String` default="nsqlogger" )* The channel name for the logger to each topic
- **exceededTopic** : *( `String` default="_exceeded" )* A topic name, that will store exceeded messages.
- **ignoreTopics** : *( `String[]|Function` default=null )* A list of topics that should be ignored or a function that will called to check the ignored topics manually
- **lookupdPollInterval** : *( `Number` default=60 )* Time in seconds to poll the nsqlookupd servers to sync the available topics
- **maxInFlight** : *( `Number` default=1 )* The maximum number of messages to process at once. This value is shared between nsqd connections. It's highly recommended that this value is greater than the number of nsqd connections.
- **heartbeatInterval** : *( `Number` default=30 )* The frequency in seconds at which the nsqd will send heartbeats to this Reader.
- **lookupdTCPAddresses** : *( `String[]` default=[ "127.0.0.1:4160", "127.0.0.1:4162" ] )* A list of nsq lookup servers
- **lookupdHTTPAddresses** : *( `String[]` default=[ "127.0.0.1:4161", "127.0.0.1:4163" ] )* A list of nsq lookup servers
- **maxAttempts** : *( `Number` default=10 )* The number of times to a message can be requeued before it will be handed to the DISCARD handler and then automatically finished. 0 means that there is no limit. If not DISCARD handler is specified and maxAttempts > 0, then the message will be finished automatically when the number attempts has been exhausted.
- **messageTimeout** : *( `Number|Null` default=null )* Message timeout in ms or `null` for no timeout
- **sampleRate** : *( `Number|Null` default=null )* Deliver a percentage of all messages received to this connection. 1 <= sampleRate <= 99
- **requeueDelay** : *( `Number|Null` default=5 )* The delay is in seconds. This is how long nsqd will hold on the message before attempting it again.
- **host** : *( `String` default="127.0.0.1" )* Host of a nsqd
- **port** : *( `Number` default=4150 )* Port of a nsqd
- **deflate** : *( `Boolean` default=false )* Use zlib Deflate compression.
- **deflateLevel** : *( `Number` default=6 )* Use zlib Deflate compression level.


## Methods

### `.activate()`

Activate the module

**Return**

*( Boolean )*: `true` if it is now activated. `false` if it was already active

### `.deactivate()`

Deactivate the module

**Return**

*( Boolean )*: `true` if it is now deactivated. `false` if it was already inactive

### `.active()`

Test if the module is currently active

**Return**

*( Boolean )*: Is active?


### `.destroy( cb )`

This will stop all readers and disconnect every connection from nsq

**Arguments** 

- **cb** : *( `Function` )* Called after destroy

## Events

### `message`

The main event to catch and process messages from all topics.

**Arguments** 

- **topic** : *( `String` )* The topic of this message
- **data** : *( `String|Object|Array` )* The message content. It tries to JSON.parse the message if possible. Otherwise it will be just a string.
- **done** : *( `String` )* You have to call this function until the message was processed. This will remove the message from the queue. Otherwise it will be requeued. If you add a argument `cb( new Error("Dooh!") )` it will interpreted as an error and this message be requeued immediately 

**Example:**

```js
logger.on( "message", function( topic, data, done ){
    // process your message.
    // E.g: writing the data to a db with the topic as tablename
    myDB.write( "INSERT INTO " + topic + " VALUES ( " + data + " )", done );
});
```


### `ready`

Emitted once the list of topics was received and the readers are created and connected.
This is just an internal helper. The Method `list` will also wait for the first response. The events `add`, `remove` and `change` are active after this first response.
**Example:**

```js
topics.on( "ready", function( err ){
    // handle the error
});
```

## Properties

### `logger.config`

<a name="logger-prop-config"></a>

Type: *( Config )*

This is the internaly used configuration.

**Attributes**

See [logger config](#config)

### `logger.Writer`

Type: *( NsqWriter )*

To write messages you can use the internal writer instance.

Details see [Writer](#writer)

### `logger.Topics`

Type: *( NsqTopics )*

The logger uses a module called [`nsq-topics`](https://github.com/mpneuried/nsq-topics) to sync the existing topics and generate the readers for each topic.
You can grab the internal used insatnce with `logger.Topics`

Details see [`nsq-topics`](https://github.com/mpneuried/nsq-topics)

### `logger.ready`

Type: *( Boolean )*

The logger is ready to use

----

# Writer

<a name="writer"></a>

## Initialize

```js
var NsqWriter = require( "nsq-logger/writer" )
```

**Example:**

```js
var NsqWriter = require( "nsq-logger/writer" );

var config = {
    clientId: "myFooClient",
    host: "127.0.0.1",
    port: 4150
};

// create the writer
var writer = new NsqWriter( config );

writer.connect();
writer.publish( "topic23", "Do some Stuff!" );
```

**Config** 

<a name="writer-config"></a>

- **clientId** : *( `String|Null` required )* An identifier used to disambiguate this client.
- **namespace** : *( `String|Null` default=null )* Internally prefix the nsq topics. This will be handled transparent, but with this it's possible to separate different environments from each other. E.g. you can run a "staging" and "live" environment on one nsq cluster.
- **active** : *( `Boolean` default=true )* Configuration to (en/dis)abel the nsq recorder
- **host** : *( `String` default="127.0.0.1" )* Host of a nsqd
- **port** : *( `Number` default=4150 )* Port of a nsqd
- **deflate** : *( `Boolean` default=false )* Use zlib Deflate compression.
- **deflateLevel** : *( `Number` default=6 )* Use zlib Deflate compression level.


## Methods

### `.connect()`

You have to connect the writer before publishing data

**Return**

*( Writer )*: retuns itself for chaining

### `.disconnect()`

disconnect the client

**Return**

*( Writer )*: retuns itself for chaining

### `.publish()`

You have to connect the writer before publishing data

**Arguments** 

- **topic** : *( `String` )* Topic name
- **data** : *( `String|Object|Array` )* Data to publish. If it's not a string it will be JSON stringified
- **cb** : *( `Function` )* Called after a successful publish

**Return**

*( Writer )*: retuns itself for chaining

**Example:**

```js
writer
  .connect()
  .publish(
  	"hello", // the topic
  	JSON.strinigify( { to: [ "nsq-logger" ] } ) // the data to send
  );
```

### `.activate()`

Activate the module

**Return**

*( Boolean )*: `true` if it is now activated. `false` if it was already active

### `.deactivate()`

Deactivate the module

**Return**

*( Boolean )*: `true` if it is now deactivated. `false` if it was already inactive

### `.active()`

Test if the module is currently active

**Return**

*( Boolean )*: Is active?


### `.destroy( cb )`

Disconnect and remove all event listeners

**Arguments** 

- **cb** : *( `Function` )* Called after destroy

## Events

### `message`

The main event to catch and process messages from all topics.

**Arguments** 

- **topic** : *( `String` )* The topic of this message
- **data** : *( `String|Object|Array` )* The message content. A String or parsed JSON data.
- **done** : *( `String` )* You have to call this function until the message was processed. This will remove the message from the queue. Otherwise it will be requeued. If you add a argument `cb( new Error("Dooh!") )` it will interpreted as an error and this message be requeued immediately 
- **msg** : *( `Message` )* The raw [nsqjs message](https://github.com/mpneuried/nsqjs/#message).

**Example:**

```js
logger.on( "message", function( topic, data, done ){
    // process your message.
    // E.g: writing the data to a db with the topic as tablename
    myDB.write( "INSERT INTO " + topic + " VALUES ( " + data + " )", done );
});
```


### `ready`

Emitted once the list of topics was received and the readers are created and connected.
This is just an internal helper. The Method `list` will also wait for the first response. The events `add`, `remove` and `change` are active after this first response.
**Example:**

```js
topics.on( "ready", function( err ){
    // handle the error
});
```

## Properties

### `writer.ready`

Type: *( Boolean )*

The writer is ready to use

### `writer.connected`

Type: *( Boolean )*

The writer is connected to `nsqd`

----

# Reader

<a name="reader"></a>

## Initialize

```js
var NsqReader = require( "nsq-logger/reader" )
var reader = NsqReader( topic, channel, config )
```

**Example:**

```js
var NsqReader = require( "nsq-logger/reader" );

var config = {
    clientId: "myFooClient",
    lookupdTCPAddresses: "127.0.0.1:4160",
    lookupdHTTPAddresses: "127.0.0.1: 4161",
};

// create the reader
var reader = new NsqReader( "topic23", "channel42", config );


reader.on( "message", function( topic, data, done ){
    // process your topic
    // Example response: -> data ="Do some Stuff!"
    
    // mark message as done
    done();
});
reader.connect();
```

**Paramater** 

**`NsqReader( topic, channel, config )`**

- **topic** : *( `String ` required )* The topic to listen to
- **channel** : *( `String` required )* The nsq channel to use or create
- **config** : *( `Object|Config` )* [Configuration object](#reader-config) or a [config object](#logger-prop-config)
 
**Config** 

<a name="reader-config"></a>

- **clientId** : *( `String|Null` required )* An identifier used to disambiguate this client.
- **namespace** : *( `String|Null` default=null )* Internally prefix the nsq topics. This will be handled transparent, but with this it's possible to separate different environments from each other. E.g. you can run a "staging" and "live" environment on one nsq cluster.
- **active** : *( `Boolean` default=true )* Configuration to (en/dis)abel the nsq recorder
- **maxInFlight** : *( `Number` default=1 )* The maximum number of messages to process at once. This value is shared between nsqd connections. It's highly recommended that this value is greater than the number of nsqd connections.
- **heartbeatInterval** : *( `Number` default=30 )* The frequency in seconds at which the nsqd will send heartbeats to this Reader.
- **lookupdTCPAddresses** : *( `String[]` default=[ "127.0.0.1:4160", "127.0.0.1:4162" ] )* A list of nsq lookup servers
- **lookupdHTTPAddresses** : *( `String[]` default=[ "127.0.0.1:4161", "127.0.0.1:4163" ] )* A list of nsq lookup servers
- **maxAttempts** : *( `Number` default=10 )* The number of times to a message can be requeued before it will be handed to the DISCARD handler and then automatically finished. 0 means that there is no limit. If not DISCARD handler is specified and maxAttempts > 0, then the message will be finished automatically when the number attempts has been exhausted.
- **messageTimeout** : *( `Number|Null` default=null )* Message timeout in ms or `null` for no timeout
- **sampleRate** : *( `Number|Null` default=null )* Deliver a percentage of all messages received to this connection. 1 <= sampleRate <= 99
- **requeueDelay** : *( `Number|Null` default=5 )* The delay is in seconds. This is how long nsqd will hold on the message before attempting it again.


## Methods

### `.connect()`

You have to connect the writer before publishing data

**Return**

*( Writer )*: retuns itself for chaining

### `.disconnect()`

disconnect the client

**Return**

*( Writer )*: retuns itself for chaining

### `.activate()`

Activate the module

**Return**

*( Boolean )*: `true` if it is now activated. `false` if it was already active

### `.deactivate()`

Deactivate the module

**Return**

*( Boolean )*: `true` if it is now deactivated. `false` if it was already inactive

### `.active()`

Test if the module is currently active

**Return**

*( Boolean )*: Is active?


### `.destroy( cb )`

Disconnect and remove all event listeners

**Arguments** 

- **cb** : *( `Function` )* Called after destroy

## Events

### `message`

The main event to catch and process messages from the defined topic.

**Arguments** 

- **data** : *( `String|Object|Array` )* The message content. A String or parsed JSON data.
- **done** : *( `String` )* You have to call this function until the message was processed. This will remove the message from the queue. Otherwise it will be requeued. If you add a argument `cb( new Error("Dooh!") )` it will interpreted as an error and this message be requeued immediately 

**Example:**

```js
logger.on( "message", function( data, done ){
    // process your message.
    // E.g: writing the data to a db
    myDB.write( "INSERT INTO mylogs VALUES ( " + data + " )", done );
});
```


### `ready`

Emitted once the list of topics was received and the readers are created and connected.
This is just an internal helper. The Method `list` will also wait for the first response. The events `add`, `remove` and `change` are active after this first response.
**Example:**

```js
topics.on( "ready", function( err ){
    // handle the error
});
```

## Properties

### `writer.ready`

Type: *( Boolean )*

The writer is ready to use

### `writer.connected`

Type: *( Boolean )*

The writer is connected to `nsqd`

----

## TODO's / IDEAS

- more tests
- use with promises

## Release History
|Version|Date|Description|
|:--:|:--:|:--|
|2.1.0|2019-01-25|compatibility with nsq < and > 1.x|
|2.0.2|2019-01-25|finally a working travis test|
|2.0.1|2019-01-25|fixed broken build|
|2.0.0|2019-01-25|update to nsq 1.x by updating nsqjs and use nsq-topics 1.x|
|1.0.0|2019-01-08|Make the module compatible with node:10 but no longer compatible with node < 5|
|0.1.3|2017-07-25|Small fix to catch JSON stringify errors within `Writer.publish`|
|0.1.2|2016-07-22|Fixed a stupid error with the host config of the writer|
|0.1.1|2016-07-19|Removed debugging output|
|0.1.0|2016-07-15|Updated dependencies [Issue#2](https://github.com/mpneuried/nsq-logger/issues/2) and optimized activate [Issue#3](https://github.com/mpneuried/nsq-logger/issues/3)|
|0.0.7|2016-01-20|Added raw nsqjs Message as last argument to the `message` event |
|0.0.6|2015-12-04|Bugfix on setting an array configuration; added code banner|
|0.0.5|2015-12-03|Added namespaces and made multiple parallel logger instances possible.|
|0.0.4|2015-12-03|configuration bugfix|
|0.0.3|2015-12-02|updated object tests|
|0.0.2|2015-12-02|Internal restructure and docs|
|0.0.1|2015-12-02|Initial version|

[![NPM](https://nodei.co/npm-dl/nsq-topics.png?months=6)](https://nodei.co/npm/nsq-topics/)

> Initially Generated with [generator-mpnodemodule](https://github.com/mpneuried/generator-mpnodemodule)

## Other projects

|Name|Description|
|:--|:--|
|[**nsq-topics**](https://github.com/mpneuried/nsq-topics)|Nsq helper to poll a nsqlookupd service for all it's topics and mirror it locally.|
|[**nsq-nodes**](https://github.com/mpneuried/nsq-nodes)|Nsq helper to poll a nsqlookupd service for all it's nodes and mirror it locally.|
|[**node-cache**](https://github.com/tcs-de/nodecache)|Simple and fast NodeJS internal caching. Node internal in memory cache like memcached.|
|[**nsq-watch**](https://github.com/mpneuried/nsq-watch)|Watch one or many topics for unprocessed messages.|
|[**rsmq**](https://github.com/smrchy/rsmq)|A really simple message queue based on redis|
|[**redis-heartbeat**](https://github.com/mpneuried/redis-heartbeat)|Pulse a heartbeat to redis. This can be used to detach or attach servers to nginx or similar problems.|
|[**systemhealth**](https://github.com/mpneuried/systemhealth)|Node module to run simple custom checks for your machine or it's connections. It will use [redis-heartbeat](https://github.com/mpneuried/redis-heartbeat) to send the current state to redis.|
|[**rsmq-cli**](https://github.com/mpneuried/rsmq-cli)|a terminal client for rsmq|
|[**rest-rsmq**](https://github.com/smrchy/rest-rsmq)|REST interface for.|
|[**redis-sessions**](https://github.com/smrchy/redis-sessions)|An advanced session store for NodeJS and Redis|
|[**connect-redis-sessions**](https://github.com/mpneuried/connect-redis-sessions)|A connect or express middleware to simply use the [redis sessions](https://github.com/smrchy/redis-sessions). With [redis sessions](https://github.com/smrchy/redis-sessions) you can handle multiple sessions per user_id.|
|[**redis-notifications**](https://github.com/mpneuried/redis-notifications)|A redis based notification engine. It implements the rsmq-worker to safely create notifications and recurring reports.|
|[**hyperrequest**](https://github.com/mpneuried/hyperrequest)|A wrapper around [hyperquest](https://github.com/substack/hyperquest) to handle the results|
|[**task-queue-worker**](https://github.com/smrchy/task-queue-worker)|A powerful tool for background processing of tasks that are run by making standard http requests
|[**soyer**](https://github.com/mpneuried/soyer)|Soyer is small lib for server side use of Google Closure Templates with node.js.|
|[**grunt-soy-compile**](https://github.com/mpneuried/grunt-soy-compile)|Compile Goggle Closure Templates ( SOY ) templates including the handling of XLIFF language files.|
|[**backlunr**](https://github.com/mpneuried/backlunr)|A solution to bring Backbone Collections together with the browser fulltext search engine Lunr.js|
|[**domel**](https://github.com/mpneuried/domel)|A simple dom helper if you want to get rid of jQuery|
|[**obj-schema**](https://github.com/mpneuried/obj-schema)|Simple module to validate an object by a predefined schema|


## The MIT License (MIT)

Copyright © 2015 M. Peter, http://www.tcs.de

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the “Software”), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
