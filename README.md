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

    var sansa = require('sansa');
    sansa.registerOutput(function(uuid, json) {
        console.log(uuid, json);
    });

## Advanced Usage

In most cases, the basic functionality of Sansa will suffice. Object graphs
can be serialized to JSON and deserialized from JSON sources. However, there
are a few use-cases where more finesse may be required.

### Typed Objects

Most objects handled by Sansa will probably be of type 'Object'. When this
is the case, Sansa will omit the type. The implicit assumption is that an
object is of type 'Object'.

There are some objects that are created by constructors. These objects have
a type other than 'Object'. Sansa will serialize the name of the type along
with the object.

When deserializing, Sansa will attempt to look up the name of the
constructor, in order to call it. If you serialize objects that require
constructors, you MUST register the constructor with Sansa before
you attempt to deserialize from the JSON.

    var Point = function Point(x,y) { this.x=x; this.y=y; }
    var sansa = require('sansa');
    sansa.registerConstructor("Point", Point);
    var myPoint = sansa.load('37dfb8b9-8c57-4519-880f-226e73a123d9');
    
#### Constructor Proxies

Some constructors need to be called with parameters. In the case of
Point above, the "x" and "y" fields can be easily deserialized after
construction. Other constructors are more complex.

In this case, it is possible to register a constructor proxy function.
The constructor proxy function takes the form:

    function constructorProxy(dObj, json, uuid, context)
    {
        // dObj = the raw result of JSON.parse
        // json = the JSON for this object
        // uuid = the uuid of the object
        // context = Sansa's own context (for very advanced use only)

        return new Point(0,0)
    }

The function is provided with all the information that Sansa has about
the object at the time. It is expected to return a properly constructed
object to Sansa. You register the constructor proxy function as follows:

    var sansa = require('sansa');
    sansa.registerConstructorProxy("Point", constructorProxy);
    var myPoint = sansa.load('37dfb8b9-8c57-4519-880f-226e73a123d9');

If you register a constructor, Sansa will call "new" for you.
If you register a proxy, the proxy is responsible for calling "new".

### Clearing State

If you want to reset Sansa's state, you can do so with the following:

    var sansa = require('sansa');
    sansa.clear();

This will remove all registered input sources, output sinks, and constructors.

## JSON Stores

Connecting Sansa to JSON stores is described above and pretty simple. My
goal for the future is to create more packages (sansa-mongo, sansa-mysql,
sansa-pgsql, etc.) that enable plug-and-play connections to JSON stores.

### sansa-fs (File System)

Because the File System ('fs') is built into Node.js, I thought it would
be handy to include sansa-fs as an example JSON store. It needs no extra
dependencies, and demonstrates how a JSON store might be used.

    var sansa = require('sansa');
    sansa.registerInput(sansa.connect.fs.input('/path/to/my/json/directory'));
    sansa.registerOutput(sansa.connect.fs.output('/path/to/my/json/directory'));
    var myObject = sansa.load('817e3b31-3cf7-47eb-ba96-c3fc90caf868');

## Limitations
Generally, if you make use of fields or values that begin with the
character '»' you might run into trouble unless you modify Sansa.

### Reserved field: uuid

Sansa tags every object with the field 'uuid'. If you are using that field to
store an actual v4 uuid in String form, that is no problem. Sansa can reuse
your own identifiers. If you need that field for something else, you'll need
to modify Sansa so that it can work with your objects.

### Reserved field: »type

Sansa makes use of the character '»' to create special tags in the
JSON. There is one special key:

    /^»type$/       Used to store the name of an object's constructor

### Reserved value: /^»[0-9]+$/

Sansa interprets the regular expression /^»[0-9]+$/ to be a Date object
stored in the format of milliseconds after the unix epoch.

### Reserved value: /^»[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/

Sansa interprets the regular expression
/^»[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/
to be a reference to another object.

### Identical constructor names

Sansa has no special way of telling identically named (but differently scoped)
constructors apart. If you have two packages which both define a Point class
with different constructors, you may need to modify Sansa in order to serialize
and deserialize object graphs correctly.

### Circular arrays

Object graphs with circular references aren't a problem for Sansa. However,
circular array references are difficult to serialize to JSON without some
ugly hacks to properly restore them.

    var arrayA = [1, 2, 3];
    var arrayB = [4, 5, 6];
    arrayA[3] = arrayB;
    arrayB[3] = arrayA;
    var sansa = require('sansa');
    sansa.save(arrayA);

Attempting to serialize this will result in an error. However the following
would be just fine:

    var a = { array: [1, 2, 3] };
    var b = { array: [4, 5, 6] };
    a.array[3] = b;
    b.array[3] = a;
    var sansa = require('sansa');
    sansa.save(a);

If you need circular arrays, you'll need to modify Sansa to accomodate your
objects, or your objects to accomodate Sansa.

## Development

In order to make modifications to Sansa, you'll need to establish a
development environment:

    git clone https://github.com/blinkdog/sansa.git
    npm install
    cake rebuild

The source files are located in src/coffee

## Why is it named 'Sansa'?

Arya Stark is my favorite character from [A Song of Ice and Fire](http://en.wikipedia.org/wiki/A_Song_of_Ice_and_Fire),
so I wrote an object graph serialization library for Java, and named it
after her.

This library written in CoffeeScript for Node.js is the sister library
to Arya. It does object graph serialization for JavaScript. So I named
this library after Arya Stark's sister, Sansa Stark.

## License

Sansa is Copyright 2013 Patrick Meade.

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU Affero General Public License as
published by the Free Software Foundation, either version 3 of the
License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU Affero General Public License for more details.

You should have received a copy of the [GNU Affero General Public License](https://www.gnu.org/licenses/agpl-3.0.txt)
along with this program.  If not, see <http://www.gnu.org/licenses/>.
