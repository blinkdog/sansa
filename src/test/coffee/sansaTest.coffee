# sansaTest.coffee
# Copyright 2015 Patrick Meade.
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

should = require 'should'
sansa = require '../lib/sansa'
{ # sansa
  RANGLE,
  TIME_TAG_RE,
  TYPE_TAG,
  UUID_RE,
  UUID_TAG_RE
} = sansa

#----------------------------------------------------------------------

describe 'sansa', ->
  beforeEach ->
    sansa.clear()

  it "will obey the laws of logic", ->
    false.should.equal false
    true.should.equal true

  describe "JSON.stringify", ->
    it "cannot handle circular structure", ->
      x = {}
      y = {}
      x.ref = y
      y.ref = x
      (-> JSON.stringify x).should.throw "Converting circular structure to JSON"

  describe "newUuid", ->
    it "will generate proper v4 UUIDs", ->
      (UUID_RE.test sansa.newUuid()).should.equal true

  describe "serialization", ->
    it "will generate a UUID for unidentified objects", (done) ->
      sansa.registerOutput (uuid, json, dObj, sObj) ->
        (UUID_RE.test uuid).should.equal true
        done()
      sansa.save {}

    it "will use an existing 'uuid' property as the identify of objects", (done) ->
      sansa.registerOutput (uuid, json, dObj, sObj) ->
        (UUID_RE.test uuid).should.equal true
        uuid.should.equal "61d8375b-54fa-45fb-9f1c-c745370b268f"
        done()
      sansa.save { uuid: "61d8375b-54fa-45fb-9f1c-c745370b268f" }

    it "will tag identified objects with a uuid property", (done) ->
      sansa.registerOutput (uuid, json, dObj, sObj) ->
        (UUID_RE.test uuid).should.equal true
        uuid.should.not.equal "602fb225-9b70-4734-9cbf-52a007b80f56"
        sObj.uuid.should.be.ok
        (UUID_RE.test sObj.uuid).should.equal true
        sObj.uuid.should.not.equal "602fb225-9b70-4734-9cbf-52a007b80f56"
        done()
      sansa.save { anotherUuid: "602fb225-9b70-4734-9cbf-52a007b80f56" }

    it "will generate a new object for serialization", (done) ->
      testObj =
        uuid: "8c239e6c-44b6-4a61-8355-36473dbecd0c"
      sansa.registerOutput (uuid, json, dObj, sObj) ->
        dObj.should.not.equal testObj
        sObj.should.equal testObj
        done()
      sansa.save testObj

    it "will copy the uuid property to the serialization object", (done) ->
      testObj =
        uuid: "2285cfe8-69df-4ca7-9b45-5394b5a2b269"
      sansa.registerOutput (uuid, json, dObj, sObj) ->
        sObj.uuid.should.be.ok
        (UUID_RE.test sObj.uuid).should.equal true
        sObj.uuid.should.equal "2285cfe8-69df-4ca7-9b45-5394b5a2b269"
        dObj.uuid.should.be.ok
        (UUID_RE.test dObj.uuid).should.equal true
        dObj.uuid.should.equal "2285cfe8-69df-4ca7-9b45-5394b5a2b269"
        dObj.uuid.should.equal sObj.uuid
        done()
      sansa.save testObj

    it "will preserve the 'uuid' property if present", (done) ->
      testObj =
        uuid: "7f21d726-cba1-4b8e-8ecc-05152a2b6ca6"
      sansa.registerOutput (uuid, json, dObj, sObj) ->
        dObj.uuid.should.be.ok
        dObj.uuid.should.equal "7f21d726-cba1-4b8e-8ecc-05152a2b6ca6"
        done()
      sansa.save testObj

    it "will preserve boolean properties if present", (done) ->
      testObj =
        uuid: "55770a64-75c9-4ec8-baa5-d93e5fc7f6b1"
        trueDat: true
        falseDat: false
      sansa.registerOutput (uuid, json, dObj, sObj) ->
        dObj.should.have.properties ['uuid', 'trueDat', 'falseDat']
        dObj.uuid.should.equal "55770a64-75c9-4ec8-baa5-d93e5fc7f6b1"
        dObj.trueDat.should.equal true
        dObj.falseDat.should.equal false
        done()
      sansa.save testObj

    it "will preserve number properties if present", (done) ->
      testObj =
        uuid: "743e621f-4431-4036-9cde-120dc77821d0"
        answerInt: 42
        answerFloat: 42.5
      sansa.registerOutput (uuid, json, dObj, sObj) ->
        dObj.should.have.properties ['uuid', 'answerInt', 'answerFloat']
        dObj.uuid.should.equal "743e621f-4431-4036-9cde-120dc77821d0"
        dObj.answerInt.should.equal 42
        dObj.answerFloat.should.equal 42.5
        done()
      sansa.save testObj

    it "will filter out function properties if present", (done) ->
      testObj =
        uuid: "d3998b48-9e49-41fe-9c48-6aeeb4e46721"
        square: (x) -> (x*x)
        cube: (x) -> (x * square x)
      sansa.registerOutput (uuid, json, dObj, sObj) ->
        dObj.should.have.property 'uuid'
        dObj.uuid.should.equal "d3998b48-9e49-41fe-9c48-6aeeb4e46721"
        dObj.should.not.have.properties ['square', 'cube']
        done()
      sansa.save testObj

    it "will convert Date objects to a special format", (done) ->
      testObj =
        uuid: "71746867-4359-4910-b126-72af066eef23"
        birthdate: new Date 1372219379607
      sansa.registerOutput (uuid, json, dObj, sObj) ->
        dObj.should.have.properties ['uuid', 'birthdate']
        dObj.uuid.should.equal "71746867-4359-4910-b126-72af066eef23"
        dObj.birthdate.should.equal RANGLE+"1372219379607"
        (TIME_TAG_RE.test dObj.birthdate).should.equal true
        done()
      sansa.save testObj

    it "will provide the JSON output of the new serialization object", (done) ->
      testObj =
        uuid: "847a985a-c560-4b4e-9e8e-0405a750851b"
        birthdate: new Date 1372220411502
      sansa.registerOutput (uuid, json, dObj, sObj) ->
        dObj.should.have.properties ['uuid', 'birthdate']
        dObj.uuid.should.equal "847a985a-c560-4b4e-9e8e-0405a750851b"
        dObj.birthdate.should.equal RANGLE+"1372220411502"
        should.exist json
        checkObj = JSON.parse json
        checkObj.should.have.properties ['uuid', 'birthdate']
        checkObj.uuid.should.equal "847a985a-c560-4b4e-9e8e-0405a750851b"
        checkObj.birthdate.should.equal RANGLE+"1372220411502"
        done()
      sansa.save testObj

    it "will preserve empty arrays if present", (done) ->
      testObj =
        uuid: "99128faf-523d-468b-9c30-a64348a8d96f"
        myEmptyArray: []
      sansa.registerOutput (uuid, json, dObj, sObj) ->
        dObj.should.have.properties ['uuid', 'myEmptyArray']
        dObj.uuid.should.equal "99128faf-523d-468b-9c30-a64348a8d96f"
        dObj.myEmptyArray.should.be.empty
        done()
      sansa.save testObj

    it "will preserve arrays containing booleans, numbers, and strings", (done) ->
      testObj =
        uuid: "5548fe5c-61f3-4372-a8bd-8ddc7741a7b6"
        myArray: [false, true, 42, 42.5, "foo", "bar", "baz"]
      sansa.registerOutput (uuid, json, dObj, sObj) ->
        dObj.should.have.properties ['uuid', 'myArray']
        dObj.uuid.should.equal "5548fe5c-61f3-4372-a8bd-8ddc7741a7b6"
        dObj.myArray.length.should.equal 7
        dObj.myArray[0].should.equal false
        dObj.myArray[1].should.equal true
        dObj.myArray[2].should.equal 42
        dObj.myArray[3].should.equal 42.5
        dObj.myArray[4].should.equal "foo"
        dObj.myArray[5].should.equal "bar"
        dObj.myArray[6].should.equal "baz"
        done()
      sansa.save testObj

    it "will preserve Date objects in arrays", (done) ->
      testObj =
        uuid: "bab84f42-6970-432b-90df-d68474aac418"
        myArray: [
          new Date(1372220411502),
          new Date(1372221411502),
          new Date(1372222411502),
          new Date(1372223411502) ]
      sansa.registerOutput (uuid, json, dObj, sObj) ->
        dObj.should.have.properties ['uuid', 'myArray']
        dObj.uuid.should.equal "bab84f42-6970-432b-90df-d68474aac418"
        dObj.myArray.should.have.length 4
        dObj.myArray[0].should.equal RANGLE+"1372220411502"
        dObj.myArray[1].should.equal RANGLE+"1372221411502"
        dObj.myArray[2].should.equal RANGLE+"1372222411502"
        dObj.myArray[3].should.equal RANGLE+"1372223411502"
        done()
      sansa.save testObj

    it "will save the object type in the serialization object", (done) ->
      class ComplexNumber
        constructor: (@r,@i) ->
      testObj = new ComplexNumber(3,2)
      testObj.uuid = "e2134bf9-a8ca-40dc-8555-ff73f8c6171d"
      sansa.registerOutput (uuid, json, dObj, sObj) ->
        dObj.should.have.properties ['uuid', TYPE_TAG]
        dObj.uuid.should.equal "e2134bf9-a8ca-40dc-8555-ff73f8c6171d"
        dObj[TYPE_TAG].should.equal 'ComplexNumber'
        dObj.r.should.equal 3
        dObj.i.should.equal 2
        done()
      sansa.save testObj

    it "will not save the object type in the source object", (done) ->
      class ComplexNumber
        constructor: (@r,@i) ->
      testObj = new ComplexNumber(3,2)
      testObj.uuid = "b21b6d0c-ed3f-4ae8-9ad4-573c1f641628"
      sansa.registerOutput (uuid, json, dObj, sObj) ->
        dObj.should.have.properties ['uuid', TYPE_TAG]
        sObj.should.not.have.property TYPE_TAG
        dObj.uuid.should.equal "b21b6d0c-ed3f-4ae8-9ad4-573c1f641628"
        dObj[TYPE_TAG].should.equal 'ComplexNumber'
        dObj.r.should.equal 3
        dObj.i.should.equal 2
        done()
      sansa.save testObj

    it "will not save empty constructor names in the serialization object", (done) ->
      ComplexNumber = (r,i) ->
        @r=r
        @i=i
      testObj = new ComplexNumber(3,2)
      testObj.uuid = "1290b1c0-eb20-4667-9550-ebfb410647f0"
      sansa.registerOutput (uuid, json, dObj, sObj) ->
        dObj.should.have.property 'uuid'
        dObj.should.not.have.property TYPE_TAG
        dObj.uuid.should.equal "1290b1c0-eb20-4667-9550-ebfb410647f0"
        dObj.r.should.equal 3
        dObj.i.should.equal 2
        done()
      sansa.save testObj

    it "will not save 'Object' as the constructor name", (done) ->
      testObj = {}
      testObj.uuid = "1290b1c0-eb20-4667-9550-ebfb410647f0"
      sansa.registerOutput (uuid, json, dObj, sObj) ->
        should.exist testObj.constructor.name
        testObj.constructor.name.should.equal 'Object'
        dObj.should.have.property 'uuid'
        dObj.uuid.should.equal "1290b1c0-eb20-4667-9550-ebfb410647f0"
        dObj.should.not.have.property TYPE_TAG
        done()
      sansa.save testObj

    it "will not save 'Array' as the constructor name", (done) ->
      testObj = [ 'abc', 'def', 'ghi' ]
      testObj.uuid = "88d4024f-bec5-4a21-b6e3-1742b0f48b1c"
      sansa.registerOutput (uuid, json, dObj, sObj) ->
        should.exist testObj.constructor.name
        testObj.constructor.name.should.equal 'Array'
        dObj.should.have.property 'uuid'
        dObj.uuid.should.equal "88d4024f-bec5-4a21-b6e3-1742b0f48b1c"
        dObj.should.not.have.property TYPE_TAG
        done()
      sansa.save testObj

    describe "object-graph serialization", ->
      testStore = null
      
      outputSaver = ->
        jsonStore = {}
        # See: http://www.lettersofnote.com/2009/10/savin-it.html
        savinIt = (uuid, json, dObj, sObj) ->
          jsonStore[uuid] = { "json":json, "dObj":dObj, "sObj":sObj }
        savinIt.find = (prop, value) ->
          for key of jsonStore
            obj = jsonStore[key]
            dObj = obj.dObj
            if dObj[prop]?
              if dObj[prop] is value
                return key
          return null
        savinIt.get = (uuid) ->
          return jsonStore[uuid]
        savinIt.getAll = ->
          return jsonStore
        return savinIt

      beforeEach ->
        testStore = outputSaver()
    
      it "will handle references to objects", ->
        pets =
          cats: 3
          dogs: 1
        alice =
          name: 'Alice'
          pets: pets
        sansa.registerOutput testStore
        sansa.save alice
        
        checkAliceUuid = testStore.find 'name', 'Alice'
        checkAliceUuid.should.be.ok
        checkAlice = testStore.get checkAliceUuid
        checkAlice.should.be.ok
        {dObj} = checkAlice
        dObj.should.have.properties ['name', 'pets']
        dObj.name.should.equal 'Alice'
        (UUID_TAG_RE.test dObj.pets).should.equal true
        checkPetsUuid = dObj.pets.substring 1
        (UUID_RE.test checkPetsUuid).should.equal true
        checkPets = testStore.get checkPetsUuid
        checkPets.should.be.ok
        {dObj} = checkPets
        dObj.should.have.properties ['cats', 'dogs']
        dObj.cats.should.equal 3
        dObj.dogs.should.equal 1

      it "will skip keys that are null", ->
        famous =
          first: 'Madonna'
          last: null
        sansa.registerOutput testStore
        sansa.save famous
        
        checkFamousUuid = testStore.find 'first', 'Madonna'
        checkFamous = testStore.get checkFamousUuid
        {dObj} = checkFamous
        dObj.should.have.property 'first'
        dObj.first.should.equal 'Madonna'
        dObj.should.not.have.property 'last'

      it "will handle arrays with objects", ->
        bob =
          type: 'Cat'
          name: 'Bob'
          sex: 'Male'
        carol =
          type: 'Dog'
          name: 'Carol'
          sex: 'Female'
        dave =
          type: 'Rabbit'
          name: 'Dave'
          sex: 'Male'
        gertrude =
          type: 'Ferret'
          name: 'Gertrude'
          sex: 'Female'
        alice =
          name: 'Alice'
          pets: [ bob, carol, dave, gertrude ]
        sansa.registerOutput testStore
        sansa.save alice
        (testStore.find 'name', 'Alice').should.be.ok
        (testStore.find 'name', 'Bob').should.be.ok
        (testStore.find 'name', 'Carol').should.be.ok
        (testStore.find 'name', 'Dave').should.be.ok
        (testStore.find 'name', 'Gertrude').should.be.ok

      it "will handle self references in objects", ->
        alice =
          name: 'Alice'
          uuid: '9f6449db-2f48-40ff-8f6f-5be629a3ad7e'
        alice.ref = alice
        sansa.registerOutput testStore
        sansa.save alice
        aliceSave = testStore.get '9f6449db-2f48-40ff-8f6f-5be629a3ad7e'
        should.exist aliceSave
        aliceSave.should.have.properties ['json', 'dObj', 'sObj']
        aliceSave.sObj.should.equal alice
        aliceSave.sObj.name.should.equal 'Alice'
        aliceSave.sObj.uuid.should.equal '9f6449db-2f48-40ff-8f6f-5be629a3ad7e'
        aliceSave.sObj.ref.should.not.equal RANGLE+'9f6449db-2f48-40ff-8f6f-5be629a3ad7e'
        aliceSave.dObj.should.not.equal alice
        aliceSave.dObj.name.should.equal 'Alice'
        aliceSave.dObj.uuid.should.equal '9f6449db-2f48-40ff-8f6f-5be629a3ad7e'
        aliceSave.dObj.ref.should.equal RANGLE+'9f6449db-2f48-40ff-8f6f-5be629a3ad7e'

      it "will handle circular references between objects", ->
        x = { uuid: '682c0f92-17e6-4f80-8da4-c07a79e0c5ba' }
        y = {}
        x.ref = y
        y.ref = x
        sansa.registerOutput testStore
        sansa.save x

        xSave = testStore.get '682c0f92-17e6-4f80-8da4-c07a79e0c5ba'
        should.exist xSave
        xSave.should.have.properties ['json', 'dObj', 'sObj']
        xSave.sObj.should.equal x
        xSave.sObj.ref.should.equal y
        xSave.sObj.ref.ref.should.equal x
        should.exist xSave.sObj.ref.uuid
        xSave.dObj.ref.should.equal RANGLE + xSave.sObj.ref.uuid

        ySave = testStore.get xSave.sObj.ref.uuid
        should.exist ySave
        ySave.should.have.properties ['json', 'dObj', 'sObj']
        ySave.sObj.should.equal y
        ySave.sObj.ref.should.equal x
        ySave.sObj.ref.ref.should.equal y
        should.exist ySave.sObj.ref.uuid
        ySave.dObj.ref.should.equal RANGLE + ySave.sObj.ref.uuid

      it "will throw when handling arrays with self references", ->
        x = { gnu: [] }
        x.gnu[0] = x.gnu
        x.gnu[1] = 'Not'
        x.gnu[2] = 'Unix'
        try
          sansa.save x
          should.fail()
        catch err
          err.should.equal "Serializing circular arrays with Sansa"

      it "will throw when handling arrays with circular references", ->
        x = { gnu: [] }
        y = { linux: [] }
        x.gnu[0] = y.linux
        y.linux[0] = x.gnu
        try
          sansa.save x
          should.fail()
        catch err
          err.should.equal "Serializing circular arrays with Sansa"

      it "will not throw when two objects reference the same array", (done) ->
        pets = [ 'cat', 'dog', 'ferret', 'rabbit' ]
        friend = { myFriendsPets: pets }
        me = { myPets: pets, myFriend: friend }
        sansa.save me
        done()

      it "will handle arrays with circular references between objects", (done) ->
        x = {}
        y = {}
        z = {}
        x.y = y
        y.z = z
        z.x = x
        a = [ x, y, z ]
        b = [ y, z, x ]
        c = [ z, x, y ]
        sansa.save c
        done()

      it "will handle arrays that contain arrays", (done) ->
        x = {}
        y = {}
        z = {}
        x.y = y
        y.z = z
        z.x = x
        a = [ x, y, z ]
        b = [ a, y, z, x ]
        c = [ b, z, x, y ]
        sansa.save c
        done()

      it "will handle arrays that contain objects that contain arrays", (done) ->
        x = {}
        y = {}
        z = {}
        x.y = y
        y.z = z
        z.x = x
        a = [ x, y, z ]
        b = [ a, y, z, x ]
        c = [ b, z, x, y ]
        x.c = c
        y.b = b
        z.a = a
        sansa.save x
        done()

  describe "deserialization", ->
    it "will ask registered inputs for JSON", (done) ->
      sansa.registerInput (uuid) ->
        if uuid is 'e5a48668-8482-492f-8846-16ef63de9a21'
          done()
      x = sansa.load 'e5a48668-8482-492f-8846-16ef63de9a21'

    it "will respect the order of input registration", ->
      ok = false
      # input handler 1: fail if we get asked for anything but the
      #                  specified uuid
      sansa.registerInput (uuid) ->
        if uuid isnt '4750fdaf-d3f5-46d3-a955-4f363547bbbd'
          should.fail()
      # input handler 2: set the flag 'ok' to true; and return a block
      #                  of valid json
      sansa.registerInput (uuid) ->
        if uuid is '4750fdaf-d3f5-46d3-a955-4f363547bbbd'
          ok = true
          return '{}'
      # input handler 3: fail if we get called at all; handler 2 should
      #                  have been the end of the chain
      sansa.registerInput (uuid) ->
        should.fail()
      x = sansa.load '4750fdaf-d3f5-46d3-a955-4f363547bbbd'
      ok.should.equal true

    it "will restore boolean, number, and string fields", ->
      sansa.registerInput (uuid) ->
        return '{"trueDat":true,"falseDat":false,"answer":42,"answerAndAHalf":42.5,"myNameIs":"Slim Shady","myFavoriteUuid":"7c9ffb5b-42cc-4c15-a9b1-a48aac4ed250"}' if uuid is "69a0b2a5-4ebd-4901-a2fc-f306d786dd41"
        return null
      testObj = sansa.load '69a0b2a5-4ebd-4901-a2fc-f306d786dd41'
      testObj.uuid.should.equal '69a0b2a5-4ebd-4901-a2fc-f306d786dd41'
      testObj.trueDat.should.equal true
      testObj.falseDat.should.equal false
      testObj.answer.should.equal 42
      testObj.answerAndAHalf.should.equal 42.5
      testObj.myNameIs.should.equal 'Slim Shady'
      testObj.myFavoriteUuid.should.equal '7c9ffb5b-42cc-4c15-a9b1-a48aac4ed250'

    it "will restore Date objects previously encoded", ->
      sansa.registerInput (uuid) ->
        return '{"birthdate":"»1372615405870"}' if uuid is "ed45144d-e8f4-4a26-8546-9c692dfe0294"
        return null
      testObj = sansa.load 'ed45144d-e8f4-4a26-8546-9c692dfe0294'
      testObj.uuid.should.equal 'ed45144d-e8f4-4a26-8546-9c692dfe0294'
      testObj.birthdate.should.eql new Date(1372615405870)

    it "will restore Date objects from the 20th century", ->
      testJson = '{ "oldenTimes": "»946684800000", "uuid": "afaf8f4f-ed9e-44b5-9f90-19860baf8f29" }'
      sansa.registerInput (uuid) ->
        return testJson if uuid is "afaf8f4f-ed9e-44b5-9f90-19860baf8f29"
        return null
      testObj = sansa.load 'afaf8f4f-ed9e-44b5-9f90-19860baf8f29'
      testObj.uuid.should.equal 'afaf8f4f-ed9e-44b5-9f90-19860baf8f29'
      testObj.oldenTimes.should.eql new Date(946684800000)

    it "will restore empty and populated arrays", ->
      sansa.registerInput (uuid) ->
        return '{"poorArray":[],"richArray":[false,true,42,42.5,"Slim Shady"]}' if uuid is "f653729a-cd4b-4050-bb69-98fe0812a7f4"
        return null
      testObj = sansa.load 'f653729a-cd4b-4050-bb69-98fe0812a7f4'
      testObj.uuid.should.equal 'f653729a-cd4b-4050-bb69-98fe0812a7f4'
      testObj.poorArray.should.eql []
      testObj.richArray[0].should.eql false
      testObj.richArray[1].should.eql true
      testObj.richArray[2].should.eql 42
      testObj.richArray[3].should.eql 42.5
      testObj.richArray[4].should.eql "Slim Shady"

    it "will restore Date objects contained in arrays", ->
      sansa.registerInput (uuid) ->
        return '{"myArray":["»1372616975455"]}' if uuid is "9195e1c1-93fe-405f-b6cf-cd0753e6f54d"
        return null
      testObj = sansa.load '9195e1c1-93fe-405f-b6cf-cd0753e6f54d'
      testObj.uuid.should.equal '9195e1c1-93fe-405f-b6cf-cd0753e6f54d'
      testObj.myArray[0].should.eql new Date(1372616975455)

    it "will use registered constructors to create objects", ->
      class ComplexNumber
        constructor: (@r,@i) ->
      sansa.registerConstructor 'ComplexNumber', ComplexNumber
      sansa.registerInput (uuid) ->
        return '{"»type":"ComplexNumber","r":3,"i":2}' if uuid is "1ca74e5b-a7c2-4a0f-aa4f-e350aac646ff"
        return null
      testObj = sansa.load '1ca74e5b-a7c2-4a0f-aa4f-e350aac646ff'
      testObj.uuid.should.equal '1ca74e5b-a7c2-4a0f-aa4f-e350aac646ff'
      testObj.r.should.eql 3
      testObj.i.should.eql 2
      should.not.exist testObj[sansa.TYPE_TAG]
      testObj.constructor.name.should.eql 'ComplexNumber'

    it "will use registered constructor proxies to create objects", ->
      class ComplexNumber
        constructor: (@r,@i) ->
      proxyOne = (dObj, json, uuid, context) ->
        throw 'dObj' if not dObj?
        throw 'json' if not json?
        throw 'uuid' if not uuid?
        throw 'context' if not context?
        return new ComplexNumber()
      sansa.registerConstructorProxy 'ComplexNumber', proxyOne
      sansa.registerInput (uuid) ->
        return '{"»type":"ComplexNumber","r":3,"i":2}' if uuid is "d8b552df-a00c-433a-b416-5223eaf9cab9"
        return null
      testObj = sansa.load 'd8b552df-a00c-433a-b416-5223eaf9cab9'
      testObj.uuid.should.equal 'd8b552df-a00c-433a-b416-5223eaf9cab9'
      testObj.r.should.eql 3
      testObj.i.should.eql 2
      should.not.exist testObj[sansa.TYPE_TAG]
      testObj.constructor.name.should.eql 'ComplexNumber'

    describe "object-graph deserialization", ->
      it "will restore objects by reference", ->
        sansa.registerInput (uuid) ->
          return '{"dogs":1,"cats":2}' if uuid is "b8945f37-6992-4bcc-a2e1-c15d7afc8087"
          return '{"name":"Alice","pets":"»b8945f37-6992-4bcc-a2e1-c15d7afc8087"}' if uuid is "8049c1de-1a4f-412d-97df-72695783eb68"
          return null
        testObj = sansa.load '8049c1de-1a4f-412d-97df-72695783eb68'
        testObj.uuid.should.equal '8049c1de-1a4f-412d-97df-72695783eb68'
        testObj.name.should.eql "Alice"
        should.exist testObj.pets
        testObj.pets.dogs.should.eql 1
        testObj.pets.cats.should.eql 2

      it "will restore objects with self-reference", ->
        sansa.registerInput (uuid) ->
          return '{"name":"Alice","self":"»89475235-5b57-470d-9f2c-f1dead2decbd"}' if uuid is "89475235-5b57-470d-9f2c-f1dead2decbd"
          return null
        testObj = sansa.load '89475235-5b57-470d-9f2c-f1dead2decbd'
        testObj.uuid.should.equal '89475235-5b57-470d-9f2c-f1dead2decbd'
        testObj.name.should.eql "Alice"
        should.exist testObj.self
        testObj.self.should.equal testObj

      it "will restore objects with circular reference", ->
        sansa.registerInput (uuid) ->
          return '{"name":"Alice","spouse":"»9034dda3-eaaa-47ea-b87f-b6d276646f50"}' if uuid is "08dc491a-6be5-4e7b-8c1f-445fe7c48088"
          return '{"name":"Bob","spouse":"»08dc491a-6be5-4e7b-8c1f-445fe7c48088"}' if uuid is "9034dda3-eaaa-47ea-b87f-b6d276646f50"
          return null
        testObj = sansa.load '08dc491a-6be5-4e7b-8c1f-445fe7c48088'
        testObj.uuid.should.equal '08dc491a-6be5-4e7b-8c1f-445fe7c48088'
        testObj.name.should.equal "Alice"
        should.exist testObj.spouse
        testObj.spouse.uuid.should.equal '9034dda3-eaaa-47ea-b87f-b6d276646f50'
        testObj.spouse.name.should.equal "Bob"
        should.exist testObj.spouse.spouse
        testObj.spouse.spouse.should.equal testObj

      it "will restore complex object graphs", ->
        sansa.registerInput (uuid) ->
          return '{"x":"»3fcfbf82-b182-4252-8834-a53fa636e604","a":["»3fcfbf82-b182-4252-8834-a53fa636e604","»12b4c306-376b-409d-9603-f58fea92271a","»33f70b3f-5944-4c9e-9582-22bd326012e2"],"uuid":"33f70b3f-5944-4c9e-9582-22bd326012e2"}' if uuid is "33f70b3f-5944-4c9e-9582-22bd326012e2"
          return '{"z":"»33f70b3f-5944-4c9e-9582-22bd326012e2","b":[["»3fcfbf82-b182-4252-8834-a53fa636e604","»12b4c306-376b-409d-9603-f58fea92271a","»33f70b3f-5944-4c9e-9582-22bd326012e2"],"»12b4c306-376b-409d-9603-f58fea92271a","»33f70b3f-5944-4c9e-9582-22bd326012e2","»3fcfbf82-b182-4252-8834-a53fa636e604"],"uuid":"12b4c306-376b-409d-9603-f58fea92271a"}' if uuid is "12b4c306-376b-409d-9603-f58fea92271a"
          return '{"y":"»12b4c306-376b-409d-9603-f58fea92271a","c":[[["»3fcfbf82-b182-4252-8834-a53fa636e604","»12b4c306-376b-409d-9603-f58fea92271a","»33f70b3f-5944-4c9e-9582-22bd326012e2"],"»12b4c306-376b-409d-9603-f58fea92271a","»33f70b3f-5944-4c9e-9582-22bd326012e2","»3fcfbf82-b182-4252-8834-a53fa636e604"],"»33f70b3f-5944-4c9e-9582-22bd326012e2","»3fcfbf82-b182-4252-8834-a53fa636e604","»12b4c306-376b-409d-9603-f58fea92271a"],"uuid":"3fcfbf82-b182-4252-8834-a53fa636e604"}' if uuid is "3fcfbf82-b182-4252-8834-a53fa636e604"
          return null
        testObj = sansa.load '3fcfbf82-b182-4252-8834-a53fa636e604'
        should.exist testObj
        x = testObj
        should.exist x.y
        y = x.y
        should.exist y.z
        z = y.z
        should.exist z.x
        z.x.should.equal x
        should.exist z.a
        a = z.a
        a[0].should.equal x
        a[1].should.equal y
        a[2].should.equal z
        should.exist y.b
        b = y.b
        b[1].should.equal y
        b[2].should.equal z
        b[3].should.equal x
        should.exist x.c
        c = x.c
        c[1].should.equal z
        c[2].should.equal x
        c[3].should.equal y
        (b[0] instanceof Array).should.equal true
        b[0][0].should.equal a[0]
        b[0][1].should.equal a[1]
        b[0][2].should.equal a[2]
        (c[0] instanceof Array).should.equal true
        c[0][0][0].should.equal b[0][0]
        c[0][0][1].should.equal b[0][1]
        c[0][0][2].should.equal b[0][2]

#----------------------------------------------------------------------
# end of sansaTest.coffee
