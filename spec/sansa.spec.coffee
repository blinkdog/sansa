# sansa.spec.coffee
# Copyright 2013 Patrick Meade. All rights reserved.
#----------------------------------------------------------------------

UUID_REGEXP = /[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}/

describe 'sansa', ->
    sansa = require '../lib/sansa'
    
    it "obeys the laws of logic", ->
        expect(false).toBe false
        expect(true).toBe true
        
    it "will generate a UUID for unidentified objects", ->
        sansaOutput = (uuid, json, dObj, sObj) ->
          expect(UUID_REGEXP.test uuid).toBe true
        sansa.registerOutput sansaOutput
        sansa.save {}

    it "will use the UUID of identified objects", ->
        sansaOutput = (uuid, json, dObj, sObj) ->
          expect(UUID_REGEXP.test uuid).toBe true
          expect(uuid).toEqual "61d8375b-54fa-45fb-9f1c-c745370b268f"
        sansa.registerOutput sansaOutput
        sansa.save { uuid: "61d8375b-54fa-45fb-9f1c-c745370b268f" }

#----------------------------------------------------------------------
# end of sansa.spec.coffee
