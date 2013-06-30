# sansa.coffee
# Copyright 2013 Patrick Meade. All rights reserved.
#----------------------------------------------------------------------

crypto = require 'crypto'
events = require 'events'

constructors = {}
inputs = []
outputs = new events.EventEmitter()

#----------------------------------------------------------------------

exports.RANGLE      = RANGLE      = '»'
exports.TIME_TAG_RE = TIME_TAG_RE = /^»[0-9]{13}$/
exports.TYPE_TAG    = TYPE_TAG    = RANGLE + 'type'
exports.TYPE_TAG_RE = TYPE_TAG_RE = /^»type$/
exports.UUID_RE     = UUID_RE     = /^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/
exports.UUID_TAG_RE = UUID_TAG_RE = /^»[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/

exports.clear = ->
  constructors = {}
  inputs = []
  outputs.removeAllListeners()

exports.load = (uuid) ->
  loadContext = {}
  loadObject loadContext, uuid

exports.registerConstructor = (name, con) ->
  constructors[name] = con

exports.registerConstructorProxy = (name, con) ->
  constructors[name] = con
  constructors[name].__proxy = true

exports.registerInput = (input) ->
  inputs.push input

exports.registerOutput = (output) ->
  outputs.addListener 'save', output

exports.save = (obj) ->
  saveContext = { arrayList: [] }
  saveObject saveContext, obj

#----------------------------------------------------------------------------

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
  if obj instanceof Array
    dObj = []
  else
    dObj = {}
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
          for checkArray in context.arrayList
            if checkArray is obj[key]
              throw "Serializing circular arrays with Sansa"
          context.arrayList.push obj[key]
          dObj[key] = dehydrate context, obj[key]
          if context.arrayList.pop() isnt obj[key]
            throw "Sansa detected corrupted save context"
        else
          uuid = identify obj[key]
          if not context[uuid]?
            saveObject context, obj[key]
          dObj[key] = RANGLE + uuid
  return dObj

#----------------------------------------------------------------------

loadObject = (context, uuid) ->
  # if we've already loaded this object, then return the one we've got
  return context[uuid] if context[uuid]?
  # see if we can load some JSON for the provided UUID
  json = loadJson uuid
  return null if not json?
  # good, we got some JSON, let's parse it into something we can rehydrate
  dObj = JSON.parse json
  dObj.uuid = uuid
  # create the canonical object, depending on the type
  if dObj instanceof Array
    context[uuid] = []
  else
    if dObj[TYPE_TAG]?
      rObjCons = constructors[dObj[TYPE_TAG]]
      if rObjCons.__proxy
        context[uuid] = rObjCons(dObj, json, uuid, context)
      else
        context[uuid] = new rObjCons()
    else
      context[uuid] = {}
  # now let's rehydrate the provided JSON into the canonical object
  rehydrate context[uuid], dObj, uuid, context
  # return the new canonical object to the caller
  return context[uuid]

loadJson = (uuid) ->
  for input in inputs
    json = input uuid
    return json if json?
  return null

rehydrate = (rObj, dObj, uuid, context) ->
  # rehydrate the properties of dObj into rObj
  for key of dObj
    switch typeof dObj[key]
      when "boolean", "number"
        rObj[key] = dObj[key]
      when "string"
        if TYPE_TAG_RE.test key
          throw "Sansa detected constructor error" if rObj.constructor.name isnt dObj[key]
        else
          if UUID_TAG_RE.test dObj[key]
            rObj[key] = loadObject context, dObj[key].substring(1)
          else if TIME_TAG_RE.test dObj[key]
            rObj[key] = new Date(parseInt(dObj[key].substring(1), 10))
          else
            rObj[key] = dObj[key]
      when "object"
        if dObj[key] instanceof Array
          rObj[key] = []
          rehydrate rObj[key], dObj[key], uuid, context
        else
          throw 'Sansa detected corrupt JSON input'

#----------------------------------------------------------------------

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
