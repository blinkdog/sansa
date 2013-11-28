# sansa.spec.coffee
# Copyright 2013 Patrick Meade.
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

describe 'sansa', ->
    sansa = require '../lib/sansa'
    UUID_RE = sansa.UUID_RE
    TIME_TAG_RE = sansa.TIME_TAG_RE
    UUID_TAG_RE = sansa.UUID_TAG_RE
    
    beforeEach ->
        sansa.clear()
      
    it "will obey the laws of logic", ->
        expect(false).toBe false
        expect(true).toBe true

    describe "JSON.stringify", ->
      it "cannot handle circular structure", ->
        x = {}
        y = {}
        x.ref = y
        y.ref = x
        expect(-> JSON.stringify x).toThrow "Converting circular structure to JSON"

    describe "newUuid", ->
      it "will generate proper v4 UUIDs", ->
        expect(UUID_RE.test sansa.newUuid()).toBe true

    describe "serialization", ->
        RANGLE = sansa.RANGLE
        TYPE_TAG = sansa.TYPE_TAG
        
        it "will generate a UUID for unidentified objects", ->
            sansaOutput = (uuid, json, dObj, sObj) ->
              expect(UUID_RE.test uuid).toBe true
            sansa.registerOutput sansaOutput
            sansa.save {}

        it "will use an existing 'uuid' property as the identify of objects", ->
            sansaOutput = (uuid, json, dObj, sObj) ->
              expect(UUID_RE.test uuid).toBe true
              expect(uuid).toEqual "61d8375b-54fa-45fb-9f1c-c745370b268f"
            sansa.registerOutput sansaOutput
            sansa.save { uuid: "61d8375b-54fa-45fb-9f1c-c745370b268f" }

        it "will tag identified objects with a uuid property", ->
            sansaOutput = (uuid, json, dObj, sObj) ->
              expect(UUID_RE.test uuid).toBe true
              expect(uuid).not.toEqual "602fb225-9b70-4734-9cbf-52a007b80f56"
              expect(sObj.uuid).toBeDefined()
              expect(UUID_RE.test sObj.uuid).toBe true
              expect(sObj.uuid).not.toEqual "602fb225-9b70-4734-9cbf-52a007b80f56"
            sansa.registerOutput sansaOutput
            sansa.save { anotherUuid: "602fb225-9b70-4734-9cbf-52a007b80f56" }

        it "will generate a new object for serialization", ->
            testObj =
              uuid: "8c239e6c-44b6-4a61-8355-36473dbecd0c"
            sansaOutput = (uuid, json, dObj, sObj) ->
              expect(dObj).not.toBe testObj
              expect(sObj).toBe testObj
            sansa.registerOutput sansaOutput
            sansa.save testObj

        it "will copy the uuid property to the serialization object", ->
            testObj =
              uuid: "2285cfe8-69df-4ca7-9b45-5394b5a2b269"
            sansaOutput = (uuid, json, dObj, sObj) ->
              expect(sObj.uuid).toBeDefined()
              expect(UUID_RE.test sObj.uuid).toBe true
              expect(sObj.uuid).toEqual "2285cfe8-69df-4ca7-9b45-5394b5a2b269"
              expect(dObj.uuid).toBeDefined()
              expect(UUID_RE.test dObj.uuid).toBe true
              expect(dObj.uuid).toEqual "2285cfe8-69df-4ca7-9b45-5394b5a2b269"
              expect(dObj.uuid).toEqual sObj.uuid
            sansa.registerOutput sansaOutput
            sansa.save testObj

        it "will preserve the 'uuid' property if present", ->
            testObj =
              uuid: "7f21d726-cba1-4b8e-8ecc-05152a2b6ca6"
            sansaOutput = (uuid, json, dObj, sObj) ->
              expect(dObj.uuid).toBeDefined()
              expect(dObj.uuid).toEqual "7f21d726-cba1-4b8e-8ecc-05152a2b6ca6"
            sansa.registerOutput sansaOutput
            sansa.save testObj

        it "will preserve boolean properties if present", ->
            testObj =
              uuid: "55770a64-75c9-4ec8-baa5-d93e5fc7f6b1"
              trueDat: true
              falseDat: false
            sansaOutput = (uuid, json, dObj, sObj) ->
              expect(dObj.uuid).toBeDefined()
              expect(dObj.uuid).toEqual "55770a64-75c9-4ec8-baa5-d93e5fc7f6b1"
              expect(dObj.trueDat).toBeDefined()
              expect(dObj.trueDat).toEqual true
              expect(dObj.falseDat).toBeDefined()
              expect(dObj.falseDat).toEqual false
            sansa.registerOutput sansaOutput
            sansa.save testObj

        it "will preserve number properties if present", ->
            testObj =
              uuid: "743e621f-4431-4036-9cde-120dc77821d0"
              answerInt: 42
              answerFloat: 42.5
            sansaOutput = (uuid, json, dObj, sObj) ->
              expect(dObj.uuid).toBeDefined()
              expect(dObj.uuid).toEqual "743e621f-4431-4036-9cde-120dc77821d0"
              expect(dObj.answerInt).toBeDefined()
              expect(dObj.answerInt).toEqual 42
              expect(dObj.answerFloat).toBeDefined()
              expect(dObj.answerFloat).toEqual 42.5
            sansa.registerOutput sansaOutput
            sansa.save testObj

        it "will filter out function properties if present", ->
            testObj =
              uuid: "d3998b48-9e49-41fe-9c48-6aeeb4e46721"
              square: (x) -> (x*x)
              cube: (x) -> (x * square x)
            sansaOutput = (uuid, json, dObj, sObj) ->
              expect(dObj.uuid).toBeDefined()
              expect(dObj.uuid).toEqual "d3998b48-9e49-41fe-9c48-6aeeb4e46721"
              expect(dObj.square).not.toBeDefined()
              expect(dObj.cube).not.toBeDefined()
            sansa.registerOutput sansaOutput
            sansa.save testObj

        it "will convert Date objects to a special format", ->
            testObj =
              uuid: "71746867-4359-4910-b126-72af066eef23"
              birthdate: new Date 1372219379607
            sansaOutput = (uuid, json, dObj, sObj) ->
              expect(dObj.uuid).toBeDefined()
              expect(dObj.uuid).toEqual "71746867-4359-4910-b126-72af066eef23"
              expect(dObj.birthdate).toBeDefined()
              expect(dObj.birthdate).toEqual RANGLE+"1372219379607"
              expect(TIME_TAG_RE.test dObj.birthdate).toBe true
            sansa.registerOutput sansaOutput
            sansa.save testObj

        it "will provide the JSON output of the new serialization object", ->
            testObj =
              uuid: "847a985a-c560-4b4e-9e8e-0405a750851b"
              birthdate: new Date 1372220411502
            sansaOutput = (uuid, json, dObj, sObj) ->
              expect(dObj.uuid).toBeDefined()
              expect(dObj.uuid).toEqual "847a985a-c560-4b4e-9e8e-0405a750851b"
              expect(dObj.birthdate).toBeDefined()
              expect(dObj.birthdate).toEqual RANGLE+"1372220411502"
              expect(json).toBeDefined()
              checkObj = JSON.parse json
              expect(checkObj.uuid).toBeDefined()
              expect(checkObj.uuid).toEqual "847a985a-c560-4b4e-9e8e-0405a750851b"
              expect(checkObj.birthdate).toBeDefined()
              expect(checkObj.birthdate).toEqual RANGLE+"1372220411502"
            sansa.registerOutput sansaOutput
            sansa.save testObj

        it "will preserve empty arrays if present", ->
          testObj =
            uuid: "99128faf-523d-468b-9c30-a64348a8d96f"
            myEmptyArray: []
          sansaOutput = (uuid, json, dObj, sObj) ->
            expect(dObj.uuid).toBeDefined()
            expect(dObj.uuid).toEqual "99128faf-523d-468b-9c30-a64348a8d96f"
            expect(dObj.myEmptyArray).toBeDefined()
            expect(dObj.myEmptyArray.length).toEqual 0
          sansa.registerOutput sansaOutput
          sansa.save testObj

        it "will preserve arrays containing booleans, numbers, and strings", ->
          testObj =
            uuid: "5548fe5c-61f3-4372-a8bd-8ddc7741a7b6"
            myArray: [false, true, 42, 42.5, "foo", "bar", "baz"]
          sansaOutput = (uuid, json, dObj, sObj) ->
            expect(dObj.uuid).toBeDefined()
            expect(dObj.uuid).toEqual "5548fe5c-61f3-4372-a8bd-8ddc7741a7b6"
            expect(dObj.myArray).toBeDefined()
            expect(dObj.myArray.length).toEqual 7
            expect(dObj.myArray[0]).toEqual false
            expect(dObj.myArray[1]).toEqual true
            expect(dObj.myArray[2]).toEqual 42
            expect(dObj.myArray[3]).toEqual 42.5
            expect(dObj.myArray[4]).toEqual "foo"
            expect(dObj.myArray[5]).toEqual "bar"
            expect(dObj.myArray[6]).toEqual "baz"
          sansa.registerOutput sansaOutput
          sansa.save testObj

        it "will preserve Date objects in arrays", ->
          testObj =
            uuid: "bab84f42-6970-432b-90df-d68474aac418"
            myArray: [
              new Date(1372220411502),
              new Date(1372221411502),
              new Date(1372222411502),
              new Date(1372223411502) ]
          sansaOutput = (uuid, json, dObj, sObj) ->
            expect(dObj.uuid).toBeDefined()
            expect(dObj.uuid).toEqual "bab84f42-6970-432b-90df-d68474aac418"
            expect(dObj.myArray).toBeDefined()
            expect(dObj.myArray.length).toEqual 4
            expect(dObj.myArray[0]).toEqual RANGLE+"1372220411502"
            expect(dObj.myArray[1]).toEqual RANGLE+"1372221411502"
            expect(dObj.myArray[2]).toEqual RANGLE+"1372222411502"
            expect(dObj.myArray[3]).toEqual RANGLE+"1372223411502"
          sansa.registerOutput sansaOutput
          sansa.save testObj

        it "will save the object type in the serialization object", ->
          class ComplexNumber
            constructor: (@r,@i) ->
          testObj = new ComplexNumber(3,2)
          testObj.uuid = "e2134bf9-a8ca-40dc-8555-ff73f8c6171d"
          sansaOutput = (uuid, json, dObj, sObj) ->
            expect(dObj.uuid).toBeDefined()
            expect(dObj.uuid).toEqual "e2134bf9-a8ca-40dc-8555-ff73f8c6171d"
            expect(dObj[TYPE_TAG]).toBeDefined()
            expect(dObj[TYPE_TAG]).toEqual 'ComplexNumber'
            expect(dObj.r).toEqual 3
            expect(dObj.i).toEqual 2
          sansa.registerOutput sansaOutput
          sansa.save testObj

        it "will not save the object type in the source object", ->
          class ComplexNumber
            constructor: (@r,@i) ->
          testObj = new ComplexNumber(3,2)
          testObj.uuid = "b21b6d0c-ed3f-4ae8-9ad4-573c1f641628"
          sansaOutput = (uuid, json, dObj, sObj) ->
            expect(dObj.uuid).toBeDefined()
            expect(dObj.uuid).toEqual "b21b6d0c-ed3f-4ae8-9ad4-573c1f641628"
            expect(dObj[TYPE_TAG]).toBeDefined()
            expect(dObj[TYPE_TAG]).toEqual 'ComplexNumber'
            expect(sObj[TYPE_TAG]).not.toBeDefined()
            expect(dObj.r).toEqual 3
            expect(dObj.i).toEqual 2
          sansa.registerOutput sansaOutput
          sansa.save testObj

        it "will not save empty constructor names in the serialization object", ->
          ComplexNumber = (r,i) ->
            @r=r
            @i=i
          testObj = new ComplexNumber(3,2)
          testObj.uuid = "1290b1c0-eb20-4667-9550-ebfb410647f0"
          sansaOutput = (uuid, json, dObj, sObj) ->
            expect(dObj.uuid).toBeDefined()
            expect(dObj.uuid).toEqual "1290b1c0-eb20-4667-9550-ebfb410647f0"
            expect(dObj[TYPE_TAG]).not.toBeDefined()
            expect(dObj.r).toEqual 3
            expect(dObj.i).toEqual 2
          sansa.registerOutput sansaOutput
          sansa.save testObj

        it "will not save 'Object' as the constructor name", ->
          testObj = {}
          testObj.uuid = "1290b1c0-eb20-4667-9550-ebfb410647f0"
          sansaOutput = (uuid, json, dObj, sObj) ->
            expect(testObj.constructor.name).toBeDefined()
            expect(testObj.constructor.name).toEqual 'Object'
            expect(dObj.uuid).toBeDefined()
            expect(dObj.uuid).toEqual "1290b1c0-eb20-4667-9550-ebfb410647f0"
            expect(dObj[TYPE_TAG]).not.toBeDefined()
          sansa.registerOutput sansaOutput
          sansa.save testObj

        it "will not save 'Array' as the constructor name", ->
          testObj = [ 'abc', 'def', 'ghi' ]
          testObj.uuid = "88d4024f-bec5-4a21-b6e3-1742b0f48b1c"
          sansaOutput = (uuid, json, dObj, sObj) ->
            expect(testObj.constructor.name).toBeDefined()
            expect(testObj.constructor.name).toEqual 'Array'
            expect(dObj.uuid).toBeDefined()
            expect(dObj.uuid).toEqual "88d4024f-bec5-4a21-b6e3-1742b0f48b1c"
            expect(dObj[TYPE_TAG]).not.toBeDefined()
          sansa.registerOutput sansaOutput
          sansa.save testObj

        describe "object-graph serialization", ->
          outputSaver = ->
            jsonStore = {}
            # See: http://www.lettersofnote.com/2009/10/savin-it.html
            savinIt = (uuid, json, dObj, sObj) ->
              jsonStore[uuid] = { "json":json, "dObj":dObj, "sObj":sObj }
            savinIt.get = (uuid) ->
              return jsonStore[uuid]
            savinIt.getAll = ->
              return jsonStore
            return savinIt
            
          it "will handle references to objects", ->
            pets =
              cats: 3
              dogs: 1
            alice =
              name: 'Alice'
              pets: pets
            sansaOutput = jasmine.createSpy 'sansaOutput'
            sansa.registerOutput sansaOutput
            sansa.save alice
            expect(sansaOutput).toHaveBeenCalledWith jasmine.any(String), jasmine.any(String), jasmine.any(Object), alice
            expect(sansaOutput).toHaveBeenCalledWith jasmine.any(String), jasmine.any(String), jasmine.any(Object), pets

          it "will skip keys that are null", ->
            famous =
              first: 'Madonna'
              last: null
            sansaOutput = jasmine.createSpy 'sansaOutput'
            sansa.registerOutput sansaOutput
            sansa.save famous
            expect(sansaOutput).toHaveBeenCalledWith jasmine.any(String), jasmine.any(String), jasmine.any(Object), famous

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
            sansaOutput = jasmine.createSpy 'sansaOutput'
            sansa.registerOutput sansaOutput
            sansa.save alice
            expect(sansaOutput).toHaveBeenCalledWith jasmine.any(String), jasmine.any(String), jasmine.any(Object), alice
            expect(sansaOutput).toHaveBeenCalledWith jasmine.any(String), jasmine.any(String), jasmine.any(Object), bob
            expect(sansaOutput).toHaveBeenCalledWith jasmine.any(String), jasmine.any(String), jasmine.any(Object), carol
            expect(sansaOutput).toHaveBeenCalledWith jasmine.any(String), jasmine.any(String), jasmine.any(Object), dave
            expect(sansaOutput).toHaveBeenCalledWith jasmine.any(String), jasmine.any(String), jasmine.any(Object), gertrude

          it "will handle self references in objects", ->
            alice =
              name: 'Alice'
              uuid: '9f6449db-2f48-40ff-8f6f-5be629a3ad7e'
            alice.ref = alice
            sansaOutput = outputSaver()
            sansa.registerOutput sansaOutput
            sansa.save alice
            aliceSave = sansaOutput.get '9f6449db-2f48-40ff-8f6f-5be629a3ad7e'
            expect(aliceSave).toBeDefined()
            expect(aliceSave.json).toBeDefined()
            expect(aliceSave.dObj).toBeDefined()
            expect(aliceSave.sObj).toBeDefined()
            expect(aliceSave.sObj).toBe alice
            expect(aliceSave.sObj.name).toBe 'Alice'
            expect(aliceSave.sObj.uuid).toBe '9f6449db-2f48-40ff-8f6f-5be629a3ad7e'
            expect(aliceSave.sObj.ref).not.toBe RANGLE+'9f6449db-2f48-40ff-8f6f-5be629a3ad7e'
            expect(aliceSave.dObj).not.toBe alice
            expect(aliceSave.dObj.name).toBe 'Alice'
            expect(aliceSave.dObj.uuid).toBe '9f6449db-2f48-40ff-8f6f-5be629a3ad7e'
            expect(aliceSave.dObj.ref).toBe RANGLE+'9f6449db-2f48-40ff-8f6f-5be629a3ad7e'

          it "will handle circular references between objects", ->
            x = { uuid: '682c0f92-17e6-4f80-8da4-c07a79e0c5ba' }
            y = {}
            x.ref = y
            y.ref = x
            sansaOutput = outputSaver()
            sansa.registerOutput sansaOutput
            sansa.save x
            
            xSave = sansaOutput.get '682c0f92-17e6-4f80-8da4-c07a79e0c5ba'
            expect(xSave).toBeDefined()
            expect(xSave.json).toBeDefined()
            expect(xSave.dObj).toBeDefined()
            expect(xSave.sObj).toBeDefined()
            expect(xSave.sObj).toBe x
            expect(xSave.sObj.ref).toBe y
            expect(xSave.sObj.ref.ref).toBe x
            expect(xSave.sObj.ref.uuid).toBeDefined()
            expect(xSave.dObj.ref).toBe RANGLE + xSave.sObj.ref.uuid

            ySave = sansaOutput.get xSave.sObj.ref.uuid
            expect(ySave).toBeDefined()
            expect(ySave.json).toBeDefined()
            expect(ySave.dObj).toBeDefined()
            expect(ySave.sObj).toBeDefined()
            expect(ySave.sObj).toBe y
            expect(ySave.sObj.ref).toBe x
            expect(ySave.sObj.ref.ref).toBe y
            expect(ySave.sObj.ref.uuid).toBeDefined()
            expect(ySave.dObj.ref).toBe RANGLE + ySave.sObj.ref.uuid

          it "will throw when handling arrays with self references", ->
            x = { gnu: [] }
            x.gnu[0] = x.gnu
            x.gnu[1] = 'Not'
            x.gnu[2] = 'Unix'
            expect(-> sansa.save x).toThrow "Serializing circular arrays with Sansa"

          it "will throw when handling arrays with circular references", ->
            x = { gnu: [] }
            y = { linux: [] }
            x.gnu[0] = y.linux
            y.linux[0] = x.gnu
            expect(-> sansa.save x).toThrow "Serializing circular arrays with Sansa"

          it "will not throw when two objects reference the same array", ->
            pets = [ 'cat', 'dog', 'ferret', 'rabbit' ]
            friend = { myFriendsPets: pets }
            me = { myPets: pets, myFriend: friend }
            expect(-> sansa.save me).not.toThrow "Serializing circular arrays with Sansa"

          it "will handle arrays with circular references between objects", ->
            x = {}
            y = {}
            z = {}
            x.y = y
            y.z = z
            z.x = x
            a = [ x, y, z ]
            b = [ y, z, x ]
            c = [ z, x, y ]
            expect(-> sansa.save c).not.toThrow()

          it "will handle arrays that contain arrays", ->
            x = {}
            y = {}
            z = {}
            x.y = y
            y.z = z
            z.x = x
            a = [ x, y, z ]
            b = [ a, y, z, x ]
            c = [ b, z, x, y ]
            expect(-> sansa.save c).not.toThrow()

          it "will handle arrays that contain objects that contain arrays", ->
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
            expect(-> sansa.save x).not.toThrow()

    describe "deserialization", ->
      RANGLE = sansa.RANGLE
      TYPE_TAG = sansa.TYPE_TAG
        
      it "will ask registered inputs for JSON", ->
        sansaInput = jasmine.createSpy 'sansaInput'
        sansa.registerInput sansaInput
        x = sansa.load 'e5a48668-8482-492f-8846-16ef63de9a21'
        expect(sansaInput).toHaveBeenCalledWith 'e5a48668-8482-492f-8846-16ef63de9a21'

      it "will respect the order of input registration", ->
        input1 = jasmine.createSpy 'input1'
        holder =
          input2: (uuid) -> return "{}"
        spyOn(holder, "input2").andCallThrough()
        input3 = jasmine.createSpy 'input3'
        sansa.registerInput input1
        sansa.registerInput holder.input2
        sansa.registerInput input3
        x = sansa.load '4750fdaf-d3f5-46d3-a955-4f363547bbbd'
        expect(input1).toHaveBeenCalledWith '4750fdaf-d3f5-46d3-a955-4f363547bbbd'
        expect(holder.input2).toHaveBeenCalledWith '4750fdaf-d3f5-46d3-a955-4f363547bbbd'
        expect(input3).not.toHaveBeenCalled()

      it "will restore boolean, number, and string fields", ->
        sansa.registerInput (uuid) ->
          return '{"trueDat":true,"falseDat":false,"answer":42,"answerAndAHalf":42.5,"myNameIs":"Slim Shady","myFavoriteUuid":"7c9ffb5b-42cc-4c15-a9b1-a48aac4ed250"}' if uuid is "69a0b2a5-4ebd-4901-a2fc-f306d786dd41"
          return null
        testObj = sansa.load '69a0b2a5-4ebd-4901-a2fc-f306d786dd41'
        expect(testObj.uuid).toBe '69a0b2a5-4ebd-4901-a2fc-f306d786dd41'
        expect(testObj.trueDat).toBe true
        expect(testObj.falseDat).toBe false
        expect(testObj.answer).toBe 42
        expect(testObj.answerAndAHalf).toBe 42.5
        expect(testObj.myNameIs).toBe 'Slim Shady'
        expect(testObj.myFavoriteUuid).toBe '7c9ffb5b-42cc-4c15-a9b1-a48aac4ed250'

      it "will restore Date objects previously encoded", ->
        sansa.registerInput (uuid) ->
          return '{"birthdate":"»1372615405870"}' if uuid is "ed45144d-e8f4-4a26-8546-9c692dfe0294"
          return null
        testObj = sansa.load 'ed45144d-e8f4-4a26-8546-9c692dfe0294'
        expect(testObj.uuid).toBe 'ed45144d-e8f4-4a26-8546-9c692dfe0294'
        expect(testObj.birthdate).toEqual new Date(1372615405870)

      it "will restore Date objects from the 20th century", ->
        testJson = '{ "oldenTimes": "»946684800000", "uuid": "afaf8f4f-ed9e-44b5-9f90-19860baf8f29" }'
        sansa.registerInput (uuid) ->
          return testJson if uuid is "afaf8f4f-ed9e-44b5-9f90-19860baf8f29"
          return null
        testObj = sansa.load 'afaf8f4f-ed9e-44b5-9f90-19860baf8f29'
        expect(testObj.uuid).toBe 'afaf8f4f-ed9e-44b5-9f90-19860baf8f29'
        expect(testObj.oldenTimes).toEqual new Date(946684800000)

      it "will restore empty and populated arrays", ->
        sansa.registerInput (uuid) ->
          return '{"poorArray":[],"richArray":[false,true,42,42.5,"Slim Shady"]}' if uuid is "f653729a-cd4b-4050-bb69-98fe0812a7f4"
          return null
        testObj = sansa.load 'f653729a-cd4b-4050-bb69-98fe0812a7f4'
        expect(testObj.uuid).toBe 'f653729a-cd4b-4050-bb69-98fe0812a7f4'
        expect(testObj.poorArray).toEqual []
        expect(testObj.richArray[0]).toEqual false
        expect(testObj.richArray[1]).toEqual true
        expect(testObj.richArray[2]).toEqual 42
        expect(testObj.richArray[3]).toEqual 42.5
        expect(testObj.richArray[4]).toEqual "Slim Shady"

      it "will restore Date objects contained in arrays", ->
        sansa.registerInput (uuid) ->
          return '{"myArray":["»1372616975455"]}' if uuid is "9195e1c1-93fe-405f-b6cf-cd0753e6f54d"
          return null
        testObj = sansa.load '9195e1c1-93fe-405f-b6cf-cd0753e6f54d'
        expect(testObj.uuid).toBe '9195e1c1-93fe-405f-b6cf-cd0753e6f54d'
        expect(testObj.myArray[0]).toEqual new Date(1372616975455)

      it "will use registered constructors to create objects", ->
        class ComplexNumber
          constructor: (@r,@i) ->
        sansa.registerConstructor 'ComplexNumber', ComplexNumber
        sansa.registerInput (uuid) ->
          return '{"»type":"ComplexNumber","r":3,"i":2}' if uuid is "1ca74e5b-a7c2-4a0f-aa4f-e350aac646ff"
          return null
        testObj = sansa.load '1ca74e5b-a7c2-4a0f-aa4f-e350aac646ff'
        expect(testObj.uuid).toBe '1ca74e5b-a7c2-4a0f-aa4f-e350aac646ff'
        expect(testObj.r).toEqual 3
        expect(testObj.i).toEqual 2
        expect(testObj[sansa.TYPE_TAG]).not.toBeDefined()
        expect(testObj.constructor.name).toEqual 'ComplexNumber'

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
        expect(testObj.uuid).toBe 'd8b552df-a00c-433a-b416-5223eaf9cab9'
        expect(testObj.r).toEqual 3
        expect(testObj.i).toEqual 2
        expect(testObj[sansa.TYPE_TAG]).not.toBeDefined()
        expect(testObj.constructor.name).toEqual 'ComplexNumber'

      describe "object-graph deserialization", ->
        it "will restore objects by reference", ->
          sansa.registerInput (uuid) ->
            return '{"dogs":1,"cats":2}' if uuid is "b8945f37-6992-4bcc-a2e1-c15d7afc8087"
            return '{"name":"Alice","pets":"»b8945f37-6992-4bcc-a2e1-c15d7afc8087"}' if uuid is "8049c1de-1a4f-412d-97df-72695783eb68"
            return null
          testObj = sansa.load '8049c1de-1a4f-412d-97df-72695783eb68'
          expect(testObj.uuid).toBe '8049c1de-1a4f-412d-97df-72695783eb68'
          expect(testObj.name).toEqual "Alice"
          expect(testObj.pets).toBeDefined()
          expect(testObj.pets.dogs).toEqual 1
          expect(testObj.pets.cats).toEqual 2
          
        it "will restore objects with self-reference", ->
          sansa.registerInput (uuid) ->
            return '{"name":"Alice","self":"»89475235-5b57-470d-9f2c-f1dead2decbd"}' if uuid is "89475235-5b57-470d-9f2c-f1dead2decbd"
            return null
          testObj = sansa.load '89475235-5b57-470d-9f2c-f1dead2decbd'
          expect(testObj.uuid).toBe '89475235-5b57-470d-9f2c-f1dead2decbd'
          expect(testObj.name).toEqual "Alice"
          expect(testObj.self).toBeDefined()
          expect(testObj.self).toBe testObj

        it "will restore objects with circular reference", ->
          sansa.registerInput (uuid) ->
            return '{"name":"Alice","spouse":"»9034dda3-eaaa-47ea-b87f-b6d276646f50"}' if uuid is "08dc491a-6be5-4e7b-8c1f-445fe7c48088"
            return '{"name":"Bob","spouse":"»08dc491a-6be5-4e7b-8c1f-445fe7c48088"}' if uuid is "9034dda3-eaaa-47ea-b87f-b6d276646f50"
            return null
          testObj = sansa.load '08dc491a-6be5-4e7b-8c1f-445fe7c48088'
          expect(testObj.uuid).toBe '08dc491a-6be5-4e7b-8c1f-445fe7c48088'
          expect(testObj.name).toEqual "Alice"
          expect(testObj.spouse).toBeDefined()
          expect(testObj.spouse.uuid).toBe '9034dda3-eaaa-47ea-b87f-b6d276646f50'
          expect(testObj.spouse.name).toEqual "Bob"
          expect(testObj.spouse.spouse).toBeDefined()
          expect(testObj.spouse.spouse).toEqual testObj

        it "will restore complex object graphs", ->
          sansa.registerInput (uuid) ->
            return '{"x":"»3fcfbf82-b182-4252-8834-a53fa636e604","a":["»3fcfbf82-b182-4252-8834-a53fa636e604","»12b4c306-376b-409d-9603-f58fea92271a","»33f70b3f-5944-4c9e-9582-22bd326012e2"],"uuid":"33f70b3f-5944-4c9e-9582-22bd326012e2"}' if uuid is "33f70b3f-5944-4c9e-9582-22bd326012e2"
            return '{"z":"»33f70b3f-5944-4c9e-9582-22bd326012e2","b":[["»3fcfbf82-b182-4252-8834-a53fa636e604","»12b4c306-376b-409d-9603-f58fea92271a","»33f70b3f-5944-4c9e-9582-22bd326012e2"],"»12b4c306-376b-409d-9603-f58fea92271a","»33f70b3f-5944-4c9e-9582-22bd326012e2","»3fcfbf82-b182-4252-8834-a53fa636e604"],"uuid":"12b4c306-376b-409d-9603-f58fea92271a"}' if uuid is "12b4c306-376b-409d-9603-f58fea92271a"
            return '{"y":"»12b4c306-376b-409d-9603-f58fea92271a","c":[[["»3fcfbf82-b182-4252-8834-a53fa636e604","»12b4c306-376b-409d-9603-f58fea92271a","»33f70b3f-5944-4c9e-9582-22bd326012e2"],"»12b4c306-376b-409d-9603-f58fea92271a","»33f70b3f-5944-4c9e-9582-22bd326012e2","»3fcfbf82-b182-4252-8834-a53fa636e604"],"»33f70b3f-5944-4c9e-9582-22bd326012e2","»3fcfbf82-b182-4252-8834-a53fa636e604","»12b4c306-376b-409d-9603-f58fea92271a"],"uuid":"3fcfbf82-b182-4252-8834-a53fa636e604"}' if uuid is "3fcfbf82-b182-4252-8834-a53fa636e604"
            return null
          testObj = sansa.load '3fcfbf82-b182-4252-8834-a53fa636e604'
          expect(testObj).toBeDefined()
          x = testObj
          expect(x.y).toBeDefined()
          y = x.y
          expect(y.z).toBeDefined()
          z = y.z
          expect(z.x).toBeDefined()
          expect(z.x).toBe x
          expect(z.a).toBeDefined()
          a = z.a
          expect(a[0]).toBe x
          expect(a[1]).toBe y
          expect(a[2]).toBe z
          expect(y.b).toBeDefined()
          b = y.b
          expect(b[1]).toBe y
          expect(b[2]).toBe z
          expect(b[3]).toBe x
          expect(x.c).toBeDefined()
          c = x.c
          expect(c[1]).toBe z
          expect(c[2]).toBe x
          expect(c[3]).toBe y
          expect(b[0] instanceof Array).toBe true
          expect(b[0][0]).toBe a[0]
          expect(b[0][1]).toBe a[1]
          expect(b[0][2]).toBe a[2]
          expect(c[0] instanceof Array).toBe true
          expect(c[0][0][0]).toBe b[0][0]
          expect(c[0][0][1]).toBe b[0][1]
          expect(c[0][0][2]).toBe b[0][2]

    describe "connection to JSON stores", ->

      describe "sansa-fs (File System)", ->
        it "gets exported by sansa", ->
          expect(sansa.connect.fs).toBeDefined()
          expect(sansa.connect.fs.input).toBeDefined()
          expect(sansa.connect.fs.output).toBeDefined()

#----------------------------------------------------------------------
# end of sansa.spec.coffee
