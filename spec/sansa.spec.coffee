# sansa.spec.coffee
# Copyright 2013 Patrick Meade. All rights reserved.
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
              console.log uuid, json, dObj, sObj
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

#      it "will use registered constructors to recreate objects", ->
#        expect(false).toBe true

#----------------------------------------------------------------------
# end of sansa.spec.coffee
