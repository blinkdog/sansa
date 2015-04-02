# sansa
Object graph serialization library in CoffeeScript for Node.js

## Motivation
When using JSON to serialize complex object graphs, it is easy to create a 
very large block of JSON with full representations of embedded objects. Even
worse, it is easy to create an object graph with cycles, which leads to a
`TypeError: Converting circular structure to JSON`.

There is no easy way to overcome these problems. The best we can hope for
is to remove all the cycles from our object graphs and be careful how we
call `JSON.stringify();`

## sansa's Solution
sansa breaks the object graph serialization problem into the problem of
serializing a number of small objects. The simple contents (boolean, number,
string, etc.) are serialized directly to JSON. References to other objects are
converted to UUIDs. Referenced objects are then serialized recursively.

### Object Graph with Cycles in JSON
    { "a": { "b": { "a": ... TypeError: Converting circular structure to JSON

### Object Graph with Cycles in sansa
    {
      "uuid": "4cdc768b-1164-40d6-b2f4-4b319bc289d2",
      "a": "»211379b8-b9c0-4202-9c4b-a399aa18e11b"
    }

    {
      "uuid": "211379b8-b9c0-4202-9c4b-a399aa18e11b",
      "b": "»4cdc768b-1164-40d6-b2f4-4b319bc289d2"
    }

## Component API
sansa provides two components in its main module:

    var sansa = require('sansa');
    var Arya = sansa.Arya;
    var AryaMemory = sansa.AryaMemory;

### AryaMemory
`AryaMemory` is an in-memory JSON store. Its functions can be provided
directly to Arya for object graph de/serialization.

An `AryaMemory` is constructed like any other object in JavaScript:

    var mem = new AryaMemory();

#### AryaMemory.input(uuid, callback)
Obtain the JSON for the provided object's UUID.

* `uuid` String: The UUID of the object for which to obtain JSON
* `callback` Function: function callback(err, json)
    * `err` Error: An error, if any (AryaMemory never passes an Error)
    * `json` String: The JSON of the requested object

Example:

    mem.input('a94beae2-881e-4e26-9fb4-de4f0f478abf', function(err, json) {
      if(err != null) {
        // handle error
      }
      // do something with json
    });

#### AryaMemory.output(uuid, json, callback)
Store the JSON of an object under the provided UUID.

* `uuid` String: The UUID of the object to put in the JSON store
* `json` String: The JSON of the object to put in the JSON store
* `callback` Function: function callback(err)
    * `err` Error: An error, if any (AryaMemory never passes an Error)

Example:

    mem.output('a94beae2-881e-4e26-9fb4-de4f0f478abf', '{}', function(err) {
      if(err != null) {
        // handle error
      }
    });

### Arya
`Arya` is the object responsible for serialization and deserialization
of object graphs.

An `Arya` is constructed like any other object in JavaScript:

    var arya = new Arya();

#### Arya.load(uuid, src, callback)
Load an object graph from a JSON store. Caller provides the UUID of the
object to be returned (`uuid`), a callback to the JSON store (`src`), and
the callback to be provided with the object after deserialization (`callback`).

* `uuid` String: The UUID of the object to load
* `src` Function: function src(uuid, callback)
    * `uuid` String: The UUID of the object to be loaded from the JSON store
    * `callback` Function: function callback(err, json)
        * `err` Error: An error, if any occur while reading from the store
        * `json` String: The JSON of the requested object
* `callback` Function: function callback(err, obj)
    * `err` Error: An error, if any are encountered while loading
    * `obj` Object: The object and connected object graph, loaded from JSON

Example:

    arya.load('a94beae2-881e-4e26-9fb4-de4f0f478abf', mem.input, function(err, obj) {
      if(err != null) {
        // handle error
      }
      // do something with obj (an object with attached object graph)
    });

#### Arya.register(name, constr, proxy)
Register a constructor or constructor proxy with Arya.

* `name` String: the name of the constructor
* `constr` Function: the constructor, or a constructor proxy function
* `proxy` Boolean: true, iff the function provided is a constructor proxy

When serializing an object graph from JavaScript objects into JSON, sansa
will record the type of an object with a named constructor. When deserializing
the object graph back from the JSON, sansa will need a reference to the
constructor in order to re-create the object.

If there are no special conditions, and a simple no-argument call to new
will suffice, then you can just pass the constructor itself to Arya. sansa
will handle the call to `new` internally:

    var ComplexNumber = function ComplexNumber(real, imag) {
        // do something with the real and imag values here
    };

    arya.register("ComplexNumber", ComplexNumber);

If there are special conditions for calling the constructor, you may
instead pass a constructor proxy to Arya. sansa ***WILL NOT*** call
`new` for you in this case. Your proxy function must do that. You
pass `true` as the third argument, in order to indicate that the
function provided is a proxy.

    var ComplexNumber = function ComplexNumber(real, imag) {
        // do something with the real and imag values here
    };

    var complexProxy = function complexProxy() {
        var num = new ComplexNumber(1, 0);
        return num;
    };

    arya.register("ComplexNumber", complexProxy, true);

The constructor proxy function is provided with four arguments:

    function constructorProxy(dObj, json, uuid, context)

* `dObj` Object: the raw result of JSON.parse 
* `json` String: the JSON for this object
* `uuid` String: the UUID of the object
* `context` Object: sansa's own context object

sansa's context object contains references to the incomplete object
graph that is currently under construction. It represents everything
sansa knows about the object graph at the time of the call to the
constructor proxy.

All of this is really advanced usage. Most of the time, you can
simply ignore the parameters to the constructor proxy function.

#### Arya.save(obj, sink, next) 
Serialize an object graph to JSON

* `obj` Object: object in graph to be stored
* `sink` Function: function sink(uuid, json, callback)
    * `uuid` String: The UUID of the object to put in the JSON store
    * `json` String: The JSON of the object to put in the JSON store
    * `callback` Function: function callback(err)
        * `err` Error: An error, if any occurs while writing to the store
* `next` Function: function next(uuid, json, callback)
    * `err` Error: An error, if any occurs while serializing the object graph
    * `uuid` String: the UUID of the object as stored in the JSON store

Example:

    arya.save({ name: "Bob" }, mem.output, function(err, uuid) {
      if(err != null) {
        // handle error
      }
      // do something with the uuid (the uuid of the provided object)
    });

## Limitations
If you make use of fields or values that begin with the character '»'
you might run into trouble unless you modify sansa.

### Reserved field: uuid
sansa tags every object in the graph with the field 'uuid'. If you are
using that field to store an actual v4 UUID in String form, that is no
problem. sansa can reuse your own identifiers. If you need that field
for something other than a v4 UUID in String form, you'll need to modify
sansa so that it can work with your objects.

### Reserved field: »type
sansa makes use of the character '»' to create special tags in the
JSON. There is one special key:

    /^»type$/       Used to store the name of an object's constructor

### Reserved value: /^»[0-9]+$/
sansa interprets the regular expression `/^»[0-9]+$/` to be a `Date` object
stored in the format of milliseconds after the unix epoch.

### Reserved value: /^»[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/
sansa interprets the regular expression
`/^»[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/`
to be a reference to another object.

### Identical constructor names
sansa has no special way of telling identically named (but differently scoped)
constructors apart. For example, if you have two packages which both define a
`Point` class, each with different constructors, you may need to modify sansa
in order to serialize and deserialize your object graphs correctly.

### Circular arrays
Object graphs with circular ***object*** references aren't a problem for
sansa. However, circular ***array*** references are difficult to serialize
to JSON without some ugly hacks to properly restore them.

    var arrayA = [1, 2, 3];
    var arrayB = [4, 5, 6];
    arrayA[3] = arrayB;
    arrayB[3] = arrayA;
    var Arya = require('sansa').Arya;
    var arya = new Arya();
    arya.save(arrayA, mem.output, function(err, uuid) {
        // there will be an error passed here!
    });

Attempting to serialize this will result in an error. However the following
would be just fine:

    var a = { array: [1, 2, 3] };
    var b = { array: [4, 5, 6] };
    a.array[3] = b;
    b.array[3] = a;
    var Arya = require('sansa').Arya;
    var arya = new Arya();
    arya.save(a, mem.output, function(err, uuid) {
        // no error here, just a uuid
    });

If you need circular arrays, you'll need to modify sansa to accomodate your
objects, or your objects to accomodate sansa.

## Development
In order to make modifications to sansa, you'll need to establish a
development environment:

    git clone https://github.com/blinkdog/sansa.git
    cd sansa
    ./configure
    npm install
    cake rebuild

### Code Coverage
You can see the [istanbul](https://www.npmjs.com/package/istanbul) coverage
report for sansa with a task in the cake file:

    cake coverage

This task will attempt to open the coverage report in a new tab in
Mozilla Firefox. If you use another browser, you'll need to modify
the `Cakefile` to specify your preferred command for viewing the
coverage report.

### Source files
The source files are located in `src/main/coffee`.

The test source files are located in `src/test/coffee`.

## License
sansa is Copyright 2015 Patrick Meade.

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
