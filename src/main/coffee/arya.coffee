# arya.coffee
# Copyright 2015-2016 Patrick Meade.
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

crypto = require "crypto"

NO_ERROR    = null
RANGLE      = "»"
TIME_TAG_RE = /^»[0-9]+$/
TYPE_TAG    = RANGLE + "type"
TYPE_TAG_RE = /^»type$/
UUID_RE     = /^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/
UUID_TAG_RE = /^»[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/

class Arya
  constructor: ->
    @_constructors = {}

  load: (uuid, src, next) ->
    NEW_CONTEXT = {}
    @_loadObject NEW_CONTEXT, uuid, src, next

  register: (name, constr, proxy) ->
    @_constructors[name] = constr
    @_constructors[name].__proxy = proxy

  save: (obj, sink, next) ->
    if (not obj?) or ((typeof obj) isnt "object") or (obj instanceof Array)  
      return next new Error("cannot save #{obj}")
    NEW_CONTEXT =
      arrayList: []
      depth: 0
    @_saveObject NEW_CONTEXT, obj, sink, next

  _dehydrate: (context, obj, sink, next) ->
    # create an appropriate destination object
    if obj instanceof Array
      dObj = []
    else
      dObj = {}
      # save the type of the source object
      type = obj.constructor.name
      dObj[TYPE_TAG] = type if type isnt "Object" and type.length > 0
    # dehydrate the source object into the destination object
    for key of obj
      if obj[key]?
        switch typeof obj[key]
          when "boolean", "number", "string"
            dObj[key] = obj[key]
          when "object"
            if obj[key] instanceof Date
              dObj[key] = RANGLE + obj[key].getTime().toString()
            else if obj[key] instanceof Array
              for checkArray in context.arrayList
                if checkArray is obj[key]
                  return next new Error("circular arrays error detected")
              context.arrayList.push obj[key]
              dObj[key] = @_dehydrate context, obj[key], sink, next
              context.arrayList.pop()
            else
              uuid = @_identify obj[key]
              if not context[uuid]?
                @_saveObject context, obj[key], sink, next
              dObj[key] = RANGLE + uuid
    return dObj

  _identify: (obj) ->
    return obj.uuid if obj.uuid?
    obj.uuid = @_uuid()

  _loadObject: (context, uuid, src, next) ->
    # if we've already loaded this object, then return the one we've got
    return next NO_ERROR, context[uuid] if context[uuid]?
    # see if we can load some JSON for the provided UUID
    src uuid, (err, json) =>
      return next err if err?
      return next NO_ERROR, null if not json?
      # good, we got some JSON, let's parse it into something we can rehydrate
      dObj = JSON.parse json
      dObj.uuid = uuid
      # create the canonical object, depending on the type
      if dObj instanceof Array
        context[uuid] = []
      else
        if dObj[TYPE_TAG]?
          rObjCons = @_constructors[dObj[TYPE_TAG]]
          if rObjCons?
            if rObjCons.__proxy
              context[uuid] = rObjCons(dObj, json, uuid, context)
            else
              context[uuid] = new rObjCons()
          else
            return next new Error("Unregistered constructor #{dObj[TYPE_TAG]}")
        else
          context[uuid] = {}
      # now let's rehydrate the provided JSON into the canonical object
      @_rehydrate context[uuid], dObj, context, uuid, src, (err) ->
        next err if err?
      # return the new canonical object to the caller
      next NO_ERROR, context[uuid]

  _rehydrate: (rObj, dObj, context, uuid, src, next) ->
    # rehydrate the properties of dObj into rObj
    for key of dObj
      switch typeof dObj[key]
        when "boolean", "number"
          rObj[key] = dObj[key]
        when "string"
          if TYPE_TAG_RE.test key
            if rObj.constructor.name isnt dObj[key]
              return next new Error("constructor error detected")
          else
            if UUID_TAG_RE.test dObj[key]
              @_loadObject context, dObj[key].substring(1), src, (err, obj) ->
                return next err if err?
                rObj[key] = obj
            else if TIME_TAG_RE.test dObj[key]
              rObj[key] = new Date(parseInt(dObj[key].substring(1), 10))
            else
              rObj[key] = dObj[key]
        when "object"
          if dObj[key] instanceof Array
            rObj[key] = []
            @_rehydrate rObj[key], dObj[key], context, uuid, src, (err) ->
              next err if err?
          else
            return next new Error("corrupt JSON input detected")
    return next NO_ERROR

  _saveObject: (context, obj, sink, next) ->
    context.depth++
    uuid = @_identify obj
    context[uuid] = obj
    dObj = @_dehydrate context, obj, sink, next
    json = JSON.stringify dObj, null, 2
    context.depth--
    sink uuid, json, (err) ->
      if context.depth is 0
        next err, uuid

  _uuid: ->
    count = 0
    rndBuf = crypto.pseudoRandomBytes 32
    # See: http://stackoverflow.com/a/2117523
    "xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx".replace /[xy]/g, (c) ->
      rndByte = rndBuf.readUInt8(count++) & 0x0f
      rndByte = ((rndByte & 0x03) | 0x08) if c is "y"
      return rndByte.toString 16

exports.Arya = Arya

#----------------------------------------------------------------------
# end of arya.coffee
