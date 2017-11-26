# SansaTest.coffee
# Copyright 2017 Patrick Meade.
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation, either version 3 of the
# License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#----------------------------------------------------------------------

UUID_RE = /^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/

should = require "should"
uuidv4 = require "uuid/v4"
{SansaMemory} = require "../lib/SansaMemory"
{Sansa} = require "../lib/Sansa"

mem = null
sansa = null

describe "Sansa", ->
  beforeEach ->
    mem = new SansaMemory()
    sansa = new Sansa()

  it "should obey the laws of logic", ->
    false.should.equal false
    true.should.equal true

  it "should be better than JSON.stringify", ->
    x = {}
    y = {}
    x.ref = y
    y.ref = x
    (-> JSON.stringify x).should.throw "Converting circular structure to JSON"
    (-> JSON.stringify y).should.throw "Converting circular structure to JSON"

  describe "load", ->
    it "should reject loading undefined", ->
      (sansa.load undefined, mem.read).should.be.rejectedWith
        message: "cannot load undefined"

    it "should reject loading non-uuid", ->
      (sansa.load "MySuperAwesomeCoolObject", mem.read).should.be.rejectedWith
        message: "cannot load MySuperAwesomeCoolObject"

    it "should accept loading a UUID", ->
      (sansa.load uuidv4(), mem.read).should.be.fulfilledWith null

  describe "save", ->
    it "should reject saving undefined", ->
      (sansa.save undefined, mem.write).should.be.rejectedWith
        message: "cannot save undefined"

    it "should reject saving null", ->
      (sansa.save null, mem.write).should.be.rejectedWith
        message: "cannot save null"

    it "should reject saving false", ->
      (sansa.save false, mem.write).should.be.rejectedWith
        message: "cannot save false"

    it "should reject saving true", ->
      (sansa.save true, mem.write).should.be.rejectedWith
        message: "cannot save true"

    it "should reject saving a number", ->
      (sansa.save 42, mem.write).should.be.rejectedWith
        message: "cannot save 42"

    it "should reject saving a string", ->
      (sansa.save "Save us!", mem.write).should.be.rejectedWith
        message: "cannot save Save us!" # and I'll whisper ... No

    it "should reject saving a Date", ->
      date = new Date()
      (sansa.save date, mem.write).should.be.rejectedWith
        message: "cannot save #{date}"

    it "should accept saving an object", ->
      result = sansa.save {}, mem.write
      result.should.be.fulfilled()
      result.should.eventually.match UUID_RE

  describe "round-trip", ->
    it "should round-trip an object without a UUID", ->
      obj = {}
      should(obj.uuid).equal undefined
      uuid = await sansa.save obj, mem.write
      obj.uuid.should.match UUID_RE
      obj.uuid.should.equal uuid
      obj2 = await sansa.load uuid, mem.read
      obj2.should.be.an.Object()
      obj2.uuid.should.match UUID_RE
      obj2.uuid.should.equal uuid
      obj2.should.eql obj
      return Promise.resolve true

    it "should round-trip an object with a UUID", ->
      obj =
        uuid: uuidv4()
      obj.uuid.should.match UUID_RE
      uuid = await sansa.save obj, mem.write
      obj2 = await sansa.load uuid, mem.read
      obj2.should.be.an.Object()
      obj2.uuid.should.match UUID_RE
      obj2.uuid.should.equal uuid
      obj2.should.eql obj
      return Promise.resolve true

    it "should round-trip an object with a bunch of stuff", ->
      RT_PROPS = [ "myArray", "myString", "myNumber", "myBoolean", "myDate", "uuid" ]
      obj =
        myArray: [1, 2, 3]
        myFunc: (arg) -> return arg
        myString: "hello, obj!"
        myNumber: 42
        myBoolean: true
        myDate: new Date()
        myRegExp: UUID_RE
        myError: new Error "Settle down, Beavis!"
        myNaN: NaN
        myNull: null
      should(obj.uuid).equal undefined
      uuid = await sansa.save obj, mem.write
      obj.uuid.should.match UUID_RE
      obj.uuid.should.equal uuid
      obj2 = await sansa.load uuid, mem.read
      obj2.should.be.an.Object()
      obj2.uuid.should.match UUID_RE
      obj2.uuid.should.equal uuid
      obj2.should.have.properties RT_PROPS
      for prop in RT_PROPS
        obj[prop].should.eql obj2[prop]
      return Promise.resolve true

    it "should reject saving objects with circular arrays", ->
      a = [ 1, 2, 3 ]
      b = [ a, 4, 5 ]
      c = [ a, b, 6 ]
      d = [ a, b, c ]
      a[0] = b
      a[1] = c
      a[2] = d
      obj =
        x: a
      (sansa.save obj, mem.write).should.be.rejectedWith
        message: "circular arrays error detected"

    it "should round-trip an object with references to other objects", ->
      objA =
        name: "Alice"
      objB =
        name: "Bob"
      objC =
        name: "Carol"
      obj =
        alice: objA
        bob: objB
        carol: objC
        friends: [ objA, objB, objC ]
      should(obj.uuid).equal undefined
      uuid = await sansa.save obj, mem.write
      obj.uuid.should.match UUID_RE
      obj.uuid.should.equal uuid
      obj2 = await sansa.load uuid, mem.read
      obj2.should.be.an.Object()
      obj2.uuid.should.match UUID_RE
      obj2.uuid.should.equal uuid
      obj2.should.eql obj
      return Promise.resolve true

    it "should round-trip an object with circular object references", ->
      objA =
        name: "Alice"
      objB =
        name: "Bob"
        next: objA
      objC =
        name: "Carol"
        next: objB
      objA.next = objC
      obj =
        friends: [objA, objB, objC]
      should(obj.uuid).equal undefined
      uuid = await sansa.save obj, mem.write
      obj.uuid.should.match UUID_RE
      obj.uuid.should.equal uuid
      obj2 = await sansa.load uuid, mem.read
      obj2.should.be.an.Object()
      obj2.uuid.should.match UUID_RE
      obj2.uuid.should.equal uuid
      obj2.should.eql obj
      return Promise.resolve true

    it "should round-trip an object with embedded arrays", ->
      obj =
        matrix: [
          [
            [ 1, 0, 0, 0 ]
            [ 0, 1, 0, 0 ]
            [ 0, 0, 1, 0 ]
            [ 0, 0, 0, 1 ]
          ]
          [
            [ 1, 0, 0, 0 ]
            [ 0, 1, 0, 0 ]
            [ 0, 0, 1, 0 ]
            [ 0, 0, 0, 1 ]
          ]
          [
            [ 1, 0, 0, 0 ]
            [ 0, 1, 0, 0 ]
            [ 0, 0, 1, 0 ]
            [ 0, 0, 0, 1 ]
          ]
          [
            [ 1, 0, 0, 0 ]
            [ 0, 1, 0, 0 ]
            [ 0, 0, 1, 0 ]
            [ 0, 0, 0, 1 ]
          ]
        ]
      should(obj.uuid).equal undefined
      uuid = await sansa.save obj, mem.write
      obj.uuid.should.match UUID_RE
      obj.uuid.should.equal uuid
      obj2 = await sansa.load uuid, mem.read
      obj2.should.be.an.Object()
      obj2.uuid.should.match UUID_RE
      obj2.uuid.should.equal uuid
      obj2.should.eql obj
      return Promise.resolve true

  describe "bad mojo", ->
    it "should detect faulty JSON with embedded objects", ->
      BAD_UUID = "5a95cf0e-5728-401a-b6c3-86ff246d11f9"
      BAD_JSON = """
        {
          "x": {
            "y": {
              "z": {
                "Eric?": "He is a bad bad man!"
              }
            }
          },
          "uuid": "#{BAD_UUID}"
        }
      """
      badJsonSupplier = (uuid) ->
        Promise.resolve BAD_JSON
      (sansa.load BAD_UUID, badJsonSupplier).should.be.rejectedWith
        message: "corrupt JSON input detected"

    it "should reject if the JSON source rejects", ->
      BAD_UUID = "5a95cf0e-5728-401a-b6c3-86ff246d11f9"
      badJsonSupplier = (uuid) ->
        Promise.reject new Error "database on fire; evacuate building"
      (sansa.load BAD_UUID, badJsonSupplier).should.be.rejectedWith
        message: "database on fire; evacuate building"

    it "should reject if the JSON sink rejects", ->
      obj =
        Happy: "Gilmore"
      badJsonBuyer = (uuid) ->
        Promise.reject new Error "dev-null-as-a-service timeout error"
      (sansa.save obj, badJsonBuyer).should.be.rejectedWith
        message: "dev-null-as-a-service timeout error"

  describe "register", ->
    it "should round-trip with registered constructors", ->
      class ComplexNumber
        constructor: (@r, @i) ->
      obj = new ComplexNumber 3, 5
      should(obj.uuid).equal undefined
      uuid = await sansa.save obj, mem.write
      obj.uuid.should.match UUID_RE
      obj.uuid.should.equal uuid
      sansa.register "ComplexNumber", ComplexNumber
      obj2 = await sansa.load uuid, mem.read
      obj2.should.be.an.Object()
      obj2.uuid.should.match UUID_RE
      obj2.uuid.should.equal uuid
      obj2.should.eql obj
      obj.should.be.an.instanceof ComplexNumber
      obj2.should.be.an.instanceof ComplexNumber
      return Promise.resolve true

    it "should reject loading without a specified constructors", ->
      class ComplexNumber
        constructor: (@r, @i) ->
      obj = new ComplexNumber 3, 5
      should(obj.uuid).equal undefined
      uuid = await sansa.save obj, mem.write
      obj.uuid.should.match UUID_RE
      obj.uuid.should.equal uuid
      #sansa.register "ComplexNumber", ComplexNumber
      (sansa.load uuid, mem.read).should.be.rejectedWith
        message: "Unregistered constructor: ComplexNumber"

    it "should reject loading after constructor registration errors", ->
      class ComplexNumber
        constructor: (@r, @i) ->
      class DragonballZ
        constructor: (power) ->
          @power = power if power > 9000
      obj = new ComplexNumber 3, 5
      should(obj.uuid).equal undefined
      uuid = await sansa.save obj, mem.write
      obj.uuid.should.match UUID_RE
      obj.uuid.should.equal uuid
      sansa.register "ComplexNumber", DragonballZ
      (sansa.load uuid, mem.read).should.be.rejectedWith
        message: "constructor error detected"

#----------------------------------------------------------------------
# end of SansaTest.coffee
