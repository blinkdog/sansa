# sansa.coffee
# Copyright 2013 Patrick Meade. All rights reserved.
#----------------------------------------------------------------------

crypto = require 'crypto'
events = require 'events'

outputs = new events.EventEmitter()

exports.RANGLE = RANGLE = '»'
exports.TIME_TAG_RE = /^»[0-9]{13}$/
exports.TYPE_TAG = TYPE_TAG = RANGLE + 'type'
exports.UUID_RE = UUID_RE = /^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/
exports.UUID_TAG_RE = /^»[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/

exports.clear = ->
  outputs.removeAllListeners()

exports.registerOutput = (output) ->
  outputs.addListener 'save', output

exports.save = (obj) ->
  saveContext = {}
  saveObject saveContext, obj
  
saveObject = (context, obj) ->
  uuid = identify obj
  context[uuid] = obj
  dObj = dehydrate context, obj
  outputs.emit 'save', uuid, JSON.stringify(dObj), dObj, obj

identify = (obj) ->
  return obj.uuid if obj.uuid? and UUID_RE.test obj.uuid
  obj.uuid = newUuid()

dehydrate = (context, obj) ->
  # create an appropriate destination object
  dObj = [] if obj instanceof Array
  dObj ?= {}
  # save the type of the source object
  type = obj.constructor.name
  dObj[TYPE_TAG] = type if type isnt 'Object' and type.length > 0
  # dehydrate the source object into the destination object
  for key of obj
    switch typeof obj[key]
      when "boolean", "number", "string"
        dObj[key] = obj[key]
      when "object"
        if obj[key] instanceof Date
          dObj[key] = RANGLE + obj[key].getTime().toString()
        else if obj[key] instanceof Array
          dObj[key] = dehydrate context, obj[key]
        else
          uuid = identify obj[key]
          if not context[uuid]?
            saveObject context, obj[key]
          dObj[key] = RANGLE + uuid
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
