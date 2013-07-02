# sansa
Object graph serialization library in CoffeeScript for Node.js

## Motivation

When using JSON to serialize complex object graphs, it is easy to create a 
very large block of JSON with full representations of embedded objects. Even
worse, it is easy to create an object graph with cycles, which leads to a
TypeError: Converting circular structure to JSON.

There is no easy way to overcome these problems. You can remove all the cycles
from your object graph and be careful how you call JSON.stringify(); 

## Sansa's Solution

Sansa breaks the object graph serialization problem into the smaller problem
of serializing a bunch of small objects. The simple contents (boolean, number,
string, etc.) are serialized directly to JSON. References to other objects are
converted to UUIDs. Referenced objects are then serialized recursively.

### Object Graph with Cycles in JSON

    { "a": { "b": { "a": ... TypeError: Converting circular structure to JSON

### Object Graph with Cycles in Sansa

    {
      "uuid": "4cdc768b-1164-40d6-b2f4-4b319bc289d2",
      "a": "»211379b8-b9c0-4202-9c4b-a399aa18e11b"
    }

    {
      "uuid": "211379b8-b9c0-4202-9c4b-a399aa18e11b",
      "b": "»4cdc768b-1164-40d6-b2f4-4b319bc289d2"
    }

## Usage

This is how you serialize an object graph to Sansa:

    var sansa = require('sansa');
    sansa.save(myObject);

This is how you deserialize an object graph from Sansa:

    var sansa = require('sansa');
    var myObject = sansa.load('a8af7511-5dc4-40fb-bffa-a9e3b5d70a2a');

The next question you might have: Where does all the JSON data go to/come from?

### Input/Output Registration

Connecting Sansa to a JSON store is simple. Register the functions
that will provide or consume JSON with Sansa and they will be used
during object graph de/serialization.

#### JSON Input

The function to provide JSON to Sansa should take the following form:

    function jsonSource(uuid)
    {
        // return a String containing a block of valid JSON
    }

Sansa will provide the UUID of the object it wishes to deserialize,
and your function should return the appropriate JSON. In practice, it
would be used like this:

    var sansa = require('sansa');
    sansa.registerInput(jsonSource);
    var myObject = sansa.load('a8af7511-5dc4-40fb-bffa-a9e3b5d70a2a');

#### JSON Output

The function to consume JSON from Sansa should take the following form:

    function jsonSink(uuid, json, serializedObj, originalObj)
    {
        // the String content of json should be stored under key uuid
    }

Sansa will provide the UUID of the object and the JSON to be stored
under that key. In practice, it would be used like this:

    var sansa = require('sansa');
    sansa.registerOutput(jsonSink);
    sansa.save(myObject);

Sansa also provides the serialized object (the object upon which
JSON.stringify was called to generate the JSON) and the original object
to be serialized. In practice, you need not worry about the last two
parameters, they are for advanced customization purposes only.

#### Multiple Registration

You can register as many input and output functions as you want.
In the input case, Sansa will query them in the order provided until
one of them returns a valid block of JSON. In the output case, Sansa
will call all of them every time an object is serialized.

To see Sansa in action, you might register the following output function:

    sansa.registerOutput(function(uuid, json) {
        console.log(uuid, json);
    });

## TODO: FINISH DOCUMENTATION

### Constructor and Constructor Proxy Registration
### Limitations
### Future Plans

## Why is it named 'Sansa'?

Arya Stark is my favorite character from [A Song of Ice and Fire](http://en.wikipedia.org/wiki/A_Song_of_Ice_and_Fire),
so I wrote an object graph serialization library for Java, and named it
after her.

This library written in CoffeeScript for Node.js is the sister library
to Arya. It does object graph serialization for JavaScript. So I named
this library after Arya Stark's sister Sansa Stark.
