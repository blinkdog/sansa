# sansa.coffee
# Copyright 2013 Patrick Meade. All rights reserved.
#----------------------------------------------------------------------

crypto = require 'crypto'
events = require 'events'

outputs = new events.EventEmitter()

exports.clear = ->
    outputs.removeAllListeners()

exports.registerOutput = (output) ->
    outputs.addListener 'save', output

exports.save = (obj) ->
    uuid = obj.uuid ? newUuid()
    dObj = dehydrate obj
    outputs.emit 'save', uuid, JSON.stringify(obj), dObj, obj

dehydrate = (obj) ->
    {}

# See: http://stackoverflow.com/a/2117523
newUuid = ->
    "xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx".replace /[xy]/g, (c) ->
        rndBuf = crypto.randomBytes 1
        rndByte = rndBuf.readUInt8(0) & 0x0f
        resByte = rndByte if c is "x"
        resByte = ((rndByte & 0x03) | 0x08) if c is "y"
        return resByte.toString 16
        
#----------------------------------------------------------------------
# end of sansa.coffee
