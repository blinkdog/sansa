# aryaTest.coffee
# Copyright 2015-2016 Patrick Meade.
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

should = require "should"
{Arya} = require "../lib/arya"
{AryaMemory} = require "../lib/arya-mem"

arya = null
mem = null

describe "arya", ->
  beforeEach ->
    arya = new Arya()
    mem = new AryaMemory()
    
  it "will obey the laws of logic", ->
    false.should.equal false
    true.should.equal true

  it "will be better than JSON.stringify", ->
    x = {}
    y = {}
    x.ref = y
    y.ref = x
    (-> JSON.stringify x).should.throw "Converting circular structure to JSON"
    (-> JSON.stringify y).should.throw "Converting circular structure to JSON"

  describe "limitations", ->
    it "will produce an error if asked to save undefined", (done) ->
      arya.save undefined, mem.output, (err, uuid) ->
        done() if err?

    it "will produce an error if asked to save null", (done) ->
      arya.save null, mem.output, (err, uuid) ->
        done() if err?

    it "will produce an error if asked to save false", (done) ->
      arya.save false, mem.output, (err, uuid) ->
        done() if err?

    it "will produce an error if asked to save true", (done) ->
      arya.save true, mem.output, (err, uuid) ->
        done() if err?

    it "will produce an error if asked to save a number", (done) ->
      arya.save 5, mem.output, (err, uuid) ->
        done() if err?

    it "will produce an error if asked to save a string", (done) ->
      arya.save "No way!", mem.output, (err, uuid) ->
        done() if err?

    it "will produce an error if asked to save an array", (done) ->
      arya.save [1,2,3], mem.output, (err, uuid) ->
        done() if err?

    it "cannot round-trip circular arrays", (done) ->
      x = []
      y = []
      z = []
      x[0] = y
      y[0] = z
      z[0] = x
      TEST_OBJ =
        circus: x
      arya.save TEST_OBJ, mem.output, (err, uuid) ->
        done() if err?

  describe "features", ->
    it "can round trip an empty object", (done) ->
      arya.save {}, mem.output, (err, uuid) ->
        throw err if err?
        throw "uuid === null" if not uuid?
        arya.load uuid, mem.input, (err, obj) ->
          throw err if err?
          throw "obj === null" if not obj?
          done() if obj.uuid is uuid

    it "can round trip an identified object", (done) ->
      TEST_UUID = "62cbb1d4-8a3c-43a1-b940-0e35372ec7fe"
      TEST_OBJ =
        uuid: TEST_UUID
      arya.save TEST_OBJ, mem.output, (err, uuid) ->
        throw err if err?
        throw "bad uuid" if uuid isnt TEST_UUID
        arya.load uuid, mem.input, (err, obj) ->
          throw err if err?
          throw "obj === null" if not obj?
          done() if obj.uuid is TEST_UUID

    it "is better than JSON.stringify", (done) ->
      x = {}
      y = {}
      x.ref = y
      y.ref = x
      arya.save x, mem.output, (err, uuid) ->
        throw err if err?
        throw "bad uuid" if not uuid?
        arya.load uuid, mem.input, (err, obj) ->
          throw err if err?
          should.exist obj
          should.exist obj.uuid
          should.exist obj.ref
          should.exist obj.ref.uuid
          obj.uuid.should.equal obj.ref.ref.uuid
          obj.ref.uuid.should.equal obj.ref.ref.ref.uuid
          done()

    it "can round-trip objects with arrays", (done) ->
      TEST_OBJ =
        numbers: [1,2,3,4,5]
      arya.save TEST_OBJ, mem.output, (err, uuid) ->
        throw err if err?
        throw "bad uuid" if not uuid?
        arya.load uuid, mem.input, (err, obj) ->
          throw err if err?
          should.exist obj
          should.exist obj.numbers
          obj.numbers.length.should.equal 5
          obj.numbers.should.eql [1,2,3,4,5]
          obj.should.not.equal TEST_OBJ
          obj.should.eql TEST_OBJ
          done()

    it "can round-trip objects with booleans", (done) ->
      TEST_OBJ =
        falseDat: false
        trueDat: true
      arya.save TEST_OBJ, mem.output, (err, uuid) ->
        throw err if err?
        throw "bad uuid" if not uuid?
        arya.load uuid, mem.input, (err, obj) ->
          throw err if err?
          should.exist obj
          obj.should.have.properties ["falseDat", "trueDat"]
          obj.falseDat.should.equal false
          obj.trueDat.should.equal true
          obj.should.not.equal TEST_OBJ
          obj.should.eql TEST_OBJ
          done()

    it "can round-trip objects with Date objects", (done) ->
      TEST_OBJ =
        birthdate: new Date(1427915590)
      arya.save TEST_OBJ, mem.output, (err, uuid) ->
        throw err if err?
        throw "bad uuid" if not uuid?
        arya.load uuid, mem.input, (err, obj) ->
          throw err if err?
          should.exist obj
          obj.should.have.property "birthdate"
          obj.birthdate.should.eql new Date(1427915590)
          obj.should.not.equal TEST_OBJ
          obj.should.eql TEST_OBJ
          done()

    it "can restore objects using constructors", (done) ->
      class ComplexNumber
        constructor: (@r, @i) ->
      arya.register "ComplexNumber", ComplexNumber
      TEST_OBJ = new ComplexNumber 2, 3
      arya.save TEST_OBJ, mem.output, (err, uuid) ->
        throw err if err?
        throw "bad uuid" if not uuid?
        arya.load uuid, mem.input, (err, obj) ->
          throw err if err?
          should.exist obj
          obj.constructor.name.should.equal "ComplexNumber"
          obj.should.have.properties ["i", "r"]
          obj.r.should.equal 2
          obj.i.should.equal 3
          obj.should.not.equal TEST_OBJ
          obj.should.eql TEST_OBJ
          done()

    it "can restore objects using constructor proxies", (done) ->
      class ComplexNumber
        constructor: (@r, @i) ->
      constrProxy = (dObj, json, uuid, context) ->
        rObj = new ComplexNumber 0, 0
        rObj.square = (x) -> x * x
        return rObj
      arya.register "ComplexNumber", constrProxy, true
      TEST_OBJ = new ComplexNumber 2, 3
      arya.save TEST_OBJ, mem.output, (err, uuid) ->
        throw err if err?
        throw "bad uuid" if not uuid?
        arya.load uuid, mem.input, (err, obj) ->
          throw err if err?
          should.exist obj
          obj.constructor.name.should.equal "ComplexNumber"
          obj.should.have.properties ["i", "r", "square"]
          obj.r.should.equal 2
          obj.i.should.equal 3
          obj.square(2).should.equal 4
          obj.should.not.equal TEST_OBJ
          done()

    it "will omit null fields", (done) ->
      TEST_OBJ =
        alice: "Alice"
        bob: null
        carol: "Carol"
      arya.save TEST_OBJ, mem.output, (err, uuid) ->
        throw err if err?
        throw "bad uuid" if not uuid?
        arya.load uuid, mem.input, (err, obj) ->
          throw err if err?
          should.exist obj
          obj.should.have.properties ["alice", "carol"]
          obj.should.not.have.property "bob"
          obj.uuid.should.equal uuid
          obj.alice.should.equal "Alice"
          obj.carol.should.equal "Carol"
          obj.should.not.equal TEST_OBJ
          done()

    it "can round trip an object with an array of objects", (done) ->
      ALICE =
        name: "Alice"
        dogs: 2
      BOB =
        name: "Bob"
        cats: 1
      CAROL =
        name: "Carol"
        dogs: 1
        cats: 1
      DAVE =
        name: "Dave"
        dogs: 0
        cats: 0
      ME =
        name: "Myself I. Me"
        friends: [ ALICE, BOB, CAROL, DAVE ]
      arya.save ME, mem.output, (err, uuid) ->
        throw err if err?
        throw "uuid === null" if not uuid?
        arya.load uuid, mem.input, (err, obj) ->
          throw err if err?
          should.exist obj
          obj.should.not.equal ME
          obj.should.eql ME
          done()

    it "can round trip a deep graph", (done) ->
      ALICE =
        name: "Alice"
      BOB =
        name: "Bob"
        bestFriend: ALICE
      CAROL =
        name: "Carol"
        bestFriend: BOB
      DAVE =
        name: "Dave"
        bestFriend: CAROL
      ME =
        name: "Me"
        bestFriend: DAVE
      arya.save ME, mem.output, (err, uuid) ->
        throw err if err?
        throw "uuid === null" if not uuid?
        arya.load uuid, mem.input, (err, obj) ->
          throw err if err?
          should.exist obj
          obj.uuid.should.equal uuid
          obj.bestFriend.name.should.equal "Dave"
          should.exist obj.bestFriend.uuid
          obj.bestFriend.bestFriend.name.should.equal "Carol"
          obj.bestFriend.bestFriend.bestFriend.name.should.equal "Bob"
          obj.bestFriend.bestFriend.bestFriend.bestFriend.name.should.equal "Alice"
          should.not.exist obj.bestFriend.bestFriend.bestFriend.bestFriend.bestFriend
          done()

  describe "error-handling", ->
    it "can detect constructor proxy errors", (done) ->
      class ComplexNumber
        constructor: (@r, @i) ->
      constrProxy = (dObj, json, uuid, context) ->
        rObj = new ComplexNumber 0, 0
        rObj.square = (x) -> x * x
        # forgot to: return rObj
      arya.register "ComplexNumber", constrProxy, true
      TEST_OBJ = new ComplexNumber 2, 3
      arya.save TEST_OBJ, mem.output, (err, uuid) ->
        throw err if err?
        throw "bad uuid" if not uuid?
        arya.load uuid, mem.input, (err, obj) ->
          done() if err?
          
    it "will pass json source errors along in load", (done) ->
      TEST_OBJ =
        alice: "Alice"
      arya.save TEST_OBJ, mem.output, (err, uuid) ->
        throw err if err?
        throw "bad uuid" if not uuid?
        srcWithErrors = (uuid, next) ->
          next new Error("bad mojo in the json store")
        arya.load uuid, srcWithErrors, (err, obj) ->
          done() if err?

    it "will handle null results from the json source without error", (done) ->
      TEST_OBJ =
        alice: "Alice"
        bob: "»f8320f1e-3fb7-4626-8b84-62531b1e35bc"
      arya.save TEST_OBJ, mem.output, (err, uuid) ->
        throw err if err?
        throw "bad uuid" if not uuid?
        arya.load uuid, mem.input, (err, obj) ->
          should.exist obj
          obj.should.have.properties ["alice", "bob"]
          obj.uuid.should.equal uuid
          obj.alice.should.equal "Alice"
          should(obj.bob).equal null
          obj.should.not.equal TEST_OBJ
          done()

    it "will pass object rehydration errors along in load", (done) ->
      TEST_OBJ =
        alice: "Alice"
        bob: "»f8320f1e-3fb7-4626-8b84-62531b1e35bc"
      arya.save TEST_OBJ, mem.output, (err, uuid) ->
        throw err if err?
        throw "bad uuid" if not uuid?
        first = true
        srcWithErrors = (uuid, next) ->
          return mem.input uuid, next if uuid isnt "f8320f1e-3fb7-4626-8b84-62531b1e35bc"
          return next new Error("bad mojo in the json store")
        arya.load uuid, srcWithErrors, (err, obj) ->
          done() if err?

    it "will pass array rehydration errors along in load", (done) ->
      TEST_OBJ =
        alice: "Alice"
        friends: [ "»f8320f1e-3fb7-4626-8b84-62531b1e35bc" ]
      arya.save TEST_OBJ, mem.output, (err, uuid) ->
        throw err if err?
        throw "bad uuid" if not uuid?
        first = true
        srcWithErrors = (uuid, next) ->
          return mem.input uuid, next if uuid isnt "f8320f1e-3fb7-4626-8b84-62531b1e35bc"
          return next new Error("bad mojo in the json store")
        arya.load uuid, srcWithErrors, (err, obj) ->
          done() if err?

    describe "corrupted json", ->
      it "can load an array from corrupted json", (done) ->
        TEST_UUID = "aa08610b-9ab7-47cf-ab06-2b01be988c97"
        mem.output TEST_UUID, "[1,2,3,4,5]", (err) ->
          throw err if err?
        arya.load TEST_UUID, mem.input, (err, obj) ->
          throw err if err?
          should.exist obj
          obj.uuid.should.equal TEST_UUID
          obj.should.be.an.array
          obj.should.have.length 5
          obj[0].should.equal 1
          obj[1].should.equal 2
          obj[2].should.equal 3
          obj[3].should.equal 4
          obj[4].should.equal 5
          done()

      it "will pass an error for subobjects in corrupted json", (done) ->
        TEST_JSON = """
          {
            "name": "Alice",
            "pets": {
              "cats": 2,
              "dogs": 2
            },
            "uuid": "aa08610b-9ab7-47cf-ab06-2b01be988c97"
          }
        """
        TEST_UUID = "aa08610b-9ab7-47cf-ab06-2b01be988c97"
        mem.output TEST_UUID, TEST_JSON, (err) ->
          throw err if err?
        arya.load TEST_UUID, mem.input, (err, obj) ->
          done() if err?

#----------------------------------------------------------------------
# end of aryaTest.coffee
