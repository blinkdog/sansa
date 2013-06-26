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
        
    describe "serialization", ->
        it "will generate a UUID for unidentified objects", ->
            sansaOutput = (uuid, json, dObj, sObj) ->
              expect(UUID_REGEXP.test uuid).toBe true
            sansa.registerOutput sansaOutput
            sansa.save {}

        it "will use the 'uuid' property of identified objects", ->
            sansaOutput = (uuid, json, dObj, sObj) ->
              expect(UUID_REGEXP.test uuid).toBe true
              expect(uuid).toEqual "61d8375b-54fa-45fb-9f1c-c745370b268f"
            sansa.registerOutput sansaOutput
            sansa.save { uuid: "61d8375b-54fa-45fb-9f1c-c745370b268f" }

        it "will generate a new object for serialization", ->
            testObj =
              uuid: "8c239e6c-44b6-4a61-8355-36473dbecd0c"
            sansaOutput = (uuid, json, dObj, sObj) ->
              expect(dObj).not.toBe testObj
              expect(sObj).toBe testObj
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

#----------------------------------------------------------------------
# end of sansa.spec.coffee
