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

## TODO: FINISH DOCUMENTATION
Yep, I need to finish this documentation.

## Design Considerations

I wanted to preserve the Array structure in the JSON output. That is,
although an Array is also a JavaScript object in its own right, I did
not want to serialize every instance of an Array separately as its
own object. There are two reasons for this:

1. The JSON format supports arrays natively, Arrays flow naturally
   along with object definition. To add a layer of indirection when
   the target format offers support seems wasteful and foolish.

2. When serializing an Array as an object, each key would also be
   serialized. That is, what would normally be represented as:

    [ "abc", "def", "ghi", "jkl", "mno" ]

   Instead gets represented as:

    [ "0":"abc", "1":"def", "2":"ghi", "3":"jkl", "4":"mno" ]

   So ignoring native support for a layer of indirection also requires
   explicit specification of what should be natural/implicit keys?
   Again, wasteful and foolish.

However, there is a tradeoff. Because of the lack of indirection, a
circular array specification cannot be properly serialized;

    x = []
    x[0] = x
    sansa.save(x)      # this will throw an exception!

Circular structure in objects (where references translate to UUIDs)
works fine in Sansa. Circular structure in arrays (where we don't
translate to UUIDs, to avoid the problems mentioned above) can't
be resolved into intelligible JSON.

Because none of my arrays are circular, I'm willing to live with
this trade-off. I'd rather have nice output JSON and live without
the circular arrays (utility of which is highly dubious?) than the
other way around.

## Why is it named 'Sansa'?

Arya Stark is my favorite character from [A Song of Ice and Fire](http://en.wikipedia.org/wiki/A_Song_of_Ice_and_Fire),
so I wrote an object graph serialization library for Java, and named it
after her.

This library written in CoffeeScript for Node.js is the sister library
to Arya. It does object graph serialization for JavaScript. So I named
this library after Arya's sister Sansa Stark.
