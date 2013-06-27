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
    outputs.emit 'save', uuid, JSON.stringify(dObj), dObj, obj

dehydrate = (obj) ->
    dObj = {}
    for key of obj
      switch typeof obj[key]
        when "boolean", "number", "string"
          dObj[key] = obj[key]
        when "object"
          if obj[key] instanceof Date
            dObj[key] =
              _sansa:
                type: "Date"
                time: obj[key].getTime()
    return dObj

# See: http://stackoverflow.com/a/2117523
exports.newUuid = newUuid = ->
  rndBuf = crypto.randomBytes 32
  count = 0
  "xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx".replace /[xy]/g, (c) ->
    rndByte = rndBuf.readUInt8(count++) & 0x0f
    rndByte = ((rndByte & 0x03) | 0x08) if c is "y"
    return rndByte.toString 16

#----------------------------------------------------------------------
# end of sansa.coffee
