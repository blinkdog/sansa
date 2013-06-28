# sansa.spec.coffee
# Copyright 2013 Patrick Meade. All rights reserved.
#----------------------------------------------------------------------

UUID_REGEXP = /[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}/
UUID_TAG_RE = /»[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}/

describe 'sansa', ->
    sansa = require '../lib/sansa'
    
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
        expect(UUID_REGEXP.test sansa.newUuid()).toBe true

    describe "serialization", ->
        RANGLE = sansa.RANGLE
        TYPE_TAG = sansa.TYPE_TAG
        
        it "will generate a UUID for unidentified objects", ->
            sansaOutput = (uuid, json, dObj, sObj) ->
              expect(UUID_REGEXP.test uuid).toBe true
            sansa.registerOutput sansaOutput
            sansa.save {}

        it "will not use the 'uuid' property as the identify of objects", ->
            sansaOutput = (uuid, json, dObj, sObj) ->
              expect(UUID_REGEXP.test uuid).toBe true
              expect(uuid).toEqual "61d8375b-54fa-45fb-9f1c-c745370b268f"
            sansa.registerOutput sansaOutput
            sansa.save { uuid: "61d8375b-54fa-45fb-9f1c-c745370b268f" }

        it "will tag identified objects with a uuid property", ->
            sansaOutput = (uuid, json, dObj, sObj) ->
              expect(UUID_REGEXP.test uuid).toBe true
              expect(uuid).not.toEqual "602fb225-9b70-4734-9cbf-52a007b80f56"
              expect(sObj.uuid).toBeDefined()
              expect(UUID_REGEXP.test sObj.uuid).toBe true
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
              expect(UUID_REGEXP.test sObj.uuid).toBe true
              expect(sObj.uuid).toEqual "2285cfe8-69df-4ca7-9b45-5394b5a2b269"
              expect(dObj.uuid).toBeDefined()
              expect(UUID_REGEXP.test dObj.uuid).toBe true
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

#        it "will handle references to objects", ->
#            expect(false).toBe true
#
#        it "will handle arrays with object", ->
#            expect(false).toBe true
#
#        it "will handle circular references between objects", ->
#            expect(false).toBe true
#
#        it "will handle arrays with circular references between objects", ->
#            expect(false).toBe true
#
#        it "will handle arrays that contain arrays", ->
#            expect(false).toBe true
#
#        it "will handle arrays that contain objects that contain arrays", ->
#            expect(false).toBe true
#
#        it "will handle objects that contain objects that contain arrays", ->
#            expect(false).toBe true
#
#        it "will handle complex object graphs with diverse types and structures", ->
#            expect(false).toBe true
#
#    describe "deserialization", ->
#        it "will use registered constructors to recreate objects", ->
#            expect(false).toBe true

#----------------------------------------------------------------------
# end of sansa.spec.coffee
