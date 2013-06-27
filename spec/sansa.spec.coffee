# sansa.spec.coffee
# Copyright 2013 Patrick Meade. All rights reserved.
#----------------------------------------------------------------------

UUID_REGEXP = /[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}/

describe 'sansa', ->
    sansa = require '../lib/sansa'
    
    beforeEach ->
        sansa.clear()
      
    it "will obey the laws of logic", ->
        expect(false).toBe false
        expect(true).toBe true

    describe "newUuid", ->
      it "will generate proper v4 UUIDs", ->
        expect(UUID_REGEXP.test sansa.newUuid()).toBe true

    describe "SANSA_ID", ->
      it "is equal to '«sansa'", ->
        expect(sansa.SANSA_ID).toBe '«sansa'

    describe "serialization", ->
        LANGLE = sansa.LANGLE 
        SANSA_ID = sansa.SANSA_ID
        it "will generate a UUID for unidentified objects", ->
            sansaOutput = (uuid, json, dObj, sObj) ->
              expect(UUID_REGEXP.test uuid).toBe true
            sansa.registerOutput sansaOutput
            sansa.save {}

        it "will not use the 'uuid' property as the identify of objects", ->
            sansaOutput = (uuid, json, dObj, sObj) ->
              expect(UUID_REGEXP.test uuid).toBe true
              expect(uuid).not.toEqual "61d8375b-54fa-45fb-9f1c-c745370b268f"
            sansa.registerOutput sansaOutput
            sansa.save { uuid: "61d8375b-54fa-45fb-9f1c-c745370b268f" }

        it "will tag identified objects with a SANSA_ID", ->
            sansaOutput = (uuid, json, dObj, sObj) ->
              expect(UUID_REGEXP.test uuid).toBe true
              expect(uuid).not.toEqual "602fb225-9b70-4734-9cbf-52a007b80f56"
              expect(sObj[SANSA_ID]).toBeDefined()
              expect(UUID_REGEXP.test sObj[SANSA_ID]).toBe true
            sansa.registerOutput sansaOutput
            sansa.save { uuid: "602fb225-9b70-4734-9cbf-52a007b80f56" }

        it "will generate a new object for serialization", ->
            testObj =
              uuid: "8c239e6c-44b6-4a61-8355-36473dbecd0c"
            sansaOutput = (uuid, json, dObj, sObj) ->
              expect(dObj).not.toBe testObj
              expect(sObj).toBe testObj
            sansa.registerOutput sansaOutput
            sansa.save testObj

        it "will copy the SANSA_ID property to the serialization object", ->
            testObj =
              uuid: "2285cfe8-69df-4ca7-9b45-5394b5a2b269"
            sansaOutput = (uuid, json, dObj, sObj) ->
              expect(sObj[SANSA_ID]).toBeDefined()
              expect(UUID_REGEXP.test sObj[SANSA_ID]).toBe true
              expect(sObj[SANSA_ID]).not.toEqual "2285cfe8-69df-4ca7-9b45-5394b5a2b269"
              expect(dObj[SANSA_ID]).toBeDefined()
              expect(UUID_REGEXP.test dObj[SANSA_ID]).toBe true
              expect(dObj[SANSA_ID]).not.toEqual "2285cfe8-69df-4ca7-9b45-5394b5a2b269"
              expect(dObj[SANSA_ID]).toEqual sObj[SANSA_ID]
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
              expect(dObj.birthdate).not.toBeDefined()
              expect(dObj[LANGLE+"birthdate"]).toBeDefined()
              expect(dObj[LANGLE+"birthdate"]).toEqual 1372219379607
            sansa.registerOutput sansaOutput
            sansa.save testObj

        it "will provide the JSON output of the new serialization object", ->
            testObj =
              uuid: "847a985a-c560-4b4e-9e8e-0405a750851b"
              birthdate: new Date 1372220411502
            sansaOutput = (uuid, json, dObj, sObj) ->
              expect(dObj.uuid).toBeDefined()
              expect(dObj.uuid).toEqual "847a985a-c560-4b4e-9e8e-0405a750851b"
              expect(dObj.birthdate).not.toBeDefined()
              expect(dObj[LANGLE+"birthdate"]).toBeDefined()
              expect(dObj[LANGLE+"birthdate"]).toEqual 1372220411502
              expect(json).toBeDefined()
              checkObj = JSON.parse json
              expect(checkObj.uuid).toBeDefined()
              expect(checkObj.uuid).toEqual "847a985a-c560-4b4e-9e8e-0405a750851b"
              expect(checkObj.birthdate).not.toBeDefined()
              expect(checkObj[LANGLE+"birthdate"]).toBeDefined()
              expect(checkObj[LANGLE+"birthdate"]).toEqual 1372220411502
            sansa.registerOutput sansaOutput
            sansa.save testObj

#----------------------------------------------------------------------
# end of sansa.spec.coffee
