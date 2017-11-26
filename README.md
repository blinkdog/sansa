# sansa
Object graph serialization library

## Motivation
When using JSON to serialize complex object graphs, it is easy to
create a very large block of JSON with full representations of embedded
objects. Even worse, it is easy to create an object graph with cycles,
which leads to:

    TypeError: Converting circular structure to JSON

There is no easy way to overcome these problems. The best we can hope
for is to remove all the cycles from our object graphs and be careful
how we call `JSON.stringify()`

## sansa's Solution
sansa breaks the object graph serialization problem into the problem of
serializing a number of small objects. The simple contents (boolean,
number, string, etc.) are serialized directly to JSON. References to
other objects are converted to UUIDs. Referenced objects are then
serialized recursively.

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

    var sansaIndex = require('sansa');
    var Sansa = sansaIndex.Sansa;
    var SansaMemory = sansaIndex.SansaMemory;

SansaMemory is an in-memory async UUID -> JSON map that stands in for
more complex JSON storage engines, like file systems, databases, or
RESTful APIs.

Sansa is a support class to serialize and deserialize object graphs.

### SansaMemory
`SansaMemory` is an in-memory JSON store. Its functions can be provided
directly to Sansa for object graph de/serialization.

A `SansaMemory` is constructed like a regular object in JavaScript:

    var mem = new SansaMemory();

#### SansaMemory.read(uuid) -> Promise
Obtain the JSON for the provided object's UUID.

* `uuid` String: The UUID of the object for which to obtain JSON

Example:

    mem.read('a94beae2-881e-4e26-9fb4-de4f0f478abf')
    .then(function(json) {
      // do something with json
    });

#### SansaMemory.write(uuid, json) -> Promise
Store the JSON of an object under the provided UUID.

* `uuid` String: The UUID of the object to put in the JSON store
* `json` String: The JSON of the object to put in the JSON store

Example:

    mem.write('a94beae2-881e-4e26-9fb4-de4f0f478abf', '{}')
    .then(function(uuid) {
      // the Promise resolves to communicate success
      // uuid = 'a94beae2-881e-4e26-9fb4-de4f0f478abf'
    });

### Sansa
`Sansa` is the class responsible for serialization and deserialization
of object graphs.

A `Sansa` object is constructed like a regular object in JavaScript:

    var sansa = new Sansa();

#### Sansa.load(uuid, source) -> Promise
Load an object graph from a JSON store. Caller provides the UUID of the
object to be returned, and an async JSON store reading function.

* `uuid` String: The UUID of the object to load
* `source` Function: function read(uuid) -> Promise
    * `uuid` String: The UUID of the object to be loaded from the JSON store

Example:

    sansa.load('a94beae2-881e-4e26-9fb4-de4f0f478abf', mem.input)
    .then(function (objectGraph) {
      // do something with objectGraph
    });

#### Sansa.register(name, ctor)
Register a constructor with Sansa.

* `name` String: the name of the constructor
* `ctor` Function: the constructor

When serializing an object graph from JavaScript objects into JSON,
sansa will record the type of an object with a named constructor. When
deserializing the object graph back from the JSON, sansa will need a
reference to the constructor in order to re-create the object.

As of sansa v0.3.2, failure to register a constructor that is necessary
for deserialization will be rejected as an error. (Thanks to @qbradq)

Constructors will be called with no arguments. Classes intended for use
with sansa should ensure that this results in a usable if empty object.

#### Sansa.save(obj, sink) -> Promise
Serialize an object graph to JSON

* `obj` Object: object in graph to be stored
* `sink` Function: function write(uuid, json) -> Promise
    * `uuid` String: The UUID of the object to put in the JSON store
    * `json` String: The JSON of the object to put in the JSON store

Example:

    sansa.save({ name: "Bob" }, mem.output)
    .then(function(uuid) {
      // do something with the uuid of the provided object
    });

## Limitations
If you make use of keys or values that begin with the character '»'
you might run into trouble unless you modify sansa.

### Reserved key: uuid
sansa tags every object in the graph with the key `uuid`. If you are
using that field to store a v4 UUID string, there is no conflict.
sansa can use the UUID identifiers that you provide. If you need that
field for something other than a v4 UUID string, you'll need to modify
sansa so that it can work with your objects.

### Reserved key: »type
sansa makes use of the character '»' to create special tags in the
JSON. There is one special key:

    »type          Used to store the name of an object's constructor

### Reserved value: »[0-9]+
sansa interprets the regular expression `/^»[0-9]+$/` to be a `Date` object
stored in the format of milliseconds after the unix epoch.

### Reserved value: »UUID
sansa interprets the regular expression
`/^»[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/`
to be a reference to another object.

### Circular arrays
Object graphs with circular ***object*** references aren't a problem for
sansa. However, circular ***array*** references are difficult to serialize
to JSON without some ugly hacks to properly restore them.

    var arrayA = [1, 2, 3];
    var arrayB = [4, 5, 6];
    arrayA[3] = arrayB;
    arrayB[3] = arrayA;
    var Sansa = require('sansa').Sansa;
    var sansa = new Sansa();
    sansa.save(arrayA, mem.output)
    .catch(function(err) {
      // there will be an error passed here!
    });

Attempting to serialize this will result in an error. However the following
would be just fine:

    var a = { array: [1, 2, 3] };
    var b = { array: [4, 5, 6] };
    a.array[3] = b;
    b.array[3] = a;
    var Sansa = require('sansa').Sansa;
    var sansa = new Sansa();
    sansa.save(a, mem.output)
    .then(function(uuid) {
      // no error here, just a uuid
    });

If you need circular arrays, you'll need to modify sansa to accomodate your
objects, or your objects to accomodate sansa.

## Development
In order to make modifications to sansa, you'll need to establish a
development environment:

    git clone https://github.com/blinkdog/sansa.git
    cd sansa
    npm install
    node_modules/.bin/cake rebuild

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
sansa  
Copyright 2015-2017 Patrick Meade.

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU Affero General Public License as
published by the Free Software Foundation, either version 3 of the
License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU Affero General Public License for more details.

You should have received a copy of the
[GNU Affero General Public License](https://www.gnu.org/licenses/agpl-3.0.txt)
along with this program.  If not, see <http://www.gnu.org/licenses/>.
