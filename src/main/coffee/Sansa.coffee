# Sansa.coffee
# Copyright 2017 Patrick Meade.
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

_ = require "underscore"
uuidv4 = require "uuid/v4"

NO_SAVE = [
  _.isArray
  _.isArguments
  _.isFunction
  _.isString
  _.isNumber
  _.isFinite
  _.isBoolean
  _.isDate
  _.isRegExp
  _.isError
  _.isNaN
  _.isNull
  _.isUndefined
]

RANGLE      = "»"
TIME_TAG_RE = /^»[0-9]+$/
TYPE_TAG    = RANGLE + "type"
TYPE_TAG_RE = /^»type$/
UUID_RE     = /^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/
UUID_TAG_RE = /^»[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/

class Sansa
  constructor: ->
    @_constructors = {}

  load: (uuid, source) ->
    if not @_isLoadable uuid
      return Promise.reject new Error "cannot load #{uuid}"
    EMPTY_CONTEXT = {}
    obj = await @_loadObject uuid, source, EMPTY_CONTEXT
    return Promise.resolve obj

  register: (name, ctor) ->
    @_constructors[name] = ctor

  save: (obj, sink) ->
    if not @_isSaveable obj
      return Promise.reject new Error "cannot save #{obj}"
    EMPTY_CONTEXT = {}
    EMPTY_ARRAYLIST = []
    uuid = await @_saveObject obj, sink, EMPTY_CONTEXT, EMPTY_ARRAYLIST
    return Promise.resolve uuid

  _dehydrate: (obj, sink, context, arrayList) ->
    # create an appropriate destination object
    if _.isArray obj
      dObj = []
    else
      dObj = {}
      # save the type of the source object
      type = obj.constructor.name
      dObj[TYPE_TAG] = type if type isnt "Object" and type.length > 0
    # for each property of obj, dehydrate it
    for key of obj
      # skip any undefined or null properties
      continue if not obj[key]?
      # depending on the property type in the source object
      switch typeof obj[key]
        # if it's a boolean, number, or string
        when "boolean", "number", "string"
          # skip any Not-a-Number properties
          continue if _.isNaN obj[key]
          # otherwise copy the property directly
          dObj[key] = obj[key]
        # if it's an object, we need to check a few cases
        when "object"
          # if the property is a Date object
          if _.isDate obj[key]
            # encode the date as a time integer
            dObj[key] = RANGLE + obj[key].getTime().toString()
          # if the property is an Array object
          else if _.isArray obj[key]
            # first make sure we don't have a circular array reference
            for checkArray in arrayList
              if checkArray is obj[key]
                return Promise.reject new Error "circular arrays error detected"
            # next, copy the circular array list and add this one
            myArrayList = arrayList.slice 0
            myArrayList.push obj[key]
            # finally, dehydrate the array itself
            dObj[key] = await @_dehydrate obj[key], sink, context, myArrayList
          # if the property is an Error
          else if _.isError obj[key]
            # skip it; no support in JSON
            continue
          # if the property is a RegExp
          else if _.isRegExp obj[key]
            # skip it; no support in JSON
            continue
          # otherwise, this is a regular old object
          else
            # identify the object
            uuid = @_identify obj[key]
            # if we don't already have it in the context
            if not context[uuid]?
              # then recursively save the object
              sObj = await @_saveObject obj[key], sink, context, arrayList
            # save the UUID pointer to the object in the dehydrate object
            dObj[key] = RANGLE + uuid
    # return the dehydrated object to the caller
    return Promise.resolve dObj

  _identify: (obj) ->
    return obj.uuid if obj.uuid?
    obj.uuid = uuidv4()

  _isLoadable: (uuid) ->
    return UUID_RE.test uuid

  _isSaveable: (obj) ->
    saveable = _.isObject obj
    for check in NO_SAVE
      saveable &= not check obj
    return saveable

  _loadObject: (uuid, source, context) ->
    # if we've already loaded this object, then return the one we've got
    return Promise.resolve context[uuid] if context[uuid]?
    # pull the dehydrated JSON from the source
    json = await source uuid
    # if we didn't get any JSON, then return null
    return Promise.resolve null if not json?
    # let's parse the JSON into something we can rehydrate
    dObj = JSON.parse json
    dObj.uuid = uuid
    # if the dehydrated object was a specific type of object
    if dObj[TYPE_TAG]?
      rObjCons = @_constructors[dObj[TYPE_TAG]]
      if rObjCons?
        context[uuid] = new rObjCons()
      else
        return Promise.reject new Error "Unregistered constructor: #{dObj[TYPE_TAG]}"
    # otherwise just create a plain old object
    else
      context[uuid] = {}
    # now let's rehydrate the provided JSON into the canonical object
    rObj = await @_rehydrate uuid, source, context, dObj, context[uuid]
    # and we'll return the rehydrated object to the caller
    return Promise.resolve rObj

  _rehydrate: (uuid, source, context, dObj, rObj) ->
    # for each property of dObj
    for key of dObj
      # depending on the type of property
      switch typeof dObj[key]
        # if it's just a boolean or number, copy it directly
        when "boolean", "number"
          rObj[key] = dObj[key]
        # if it's a string, we need to check for special cases
        when "string"
          # if it's the special field indicating object type
          if TYPE_TAG_RE.test key
            # if the rObj we've been provided isn't that type
            if rObj.constructor.name isnt dObj[key]
              # this is an error!
              return Promise.reject new Error "constructor error detected"
          else
            # if it's a pointer to another object
            if UUID_TAG_RE.test dObj[key]
              # load that object
              sUuid = dObj[key].substring 1
              sObj = await @_loadObject sUuid, source, context
              rObj[key] = sObj
            # if it's a Date encoded as a time integer
            else if TIME_TAG_RE.test dObj[key]
              rObj[key] = new Date parseInt dObj[key].substring(1), 10
            # otherwise, it's a plain old string, copy it directly
            else
              rObj[key] = dObj[key]
        # if it's an object
        when "object"
          # if the object is an array
          if _.isArray dObj[key]
            # create an empty array in our rehydrated object
            rObj[key] = []
            # rehydrate that array
            await @_rehydrate uuid, source, context, dObj[key], rObj[key]
          # otherwise, we've got an embedded object (ERROR!)
          else
            # sansa creates UUID pointers to objects, it never embeds them
            return Promise.reject new Error "corrupt JSON input detected"
    # return the rehydrated object to the caller
    return Promise.resolve rObj

  _saveObject: (obj, sink, context, arrayList) ->
    uuid = @_identify obj
    context[uuid] = obj
    dObj = await @_dehydrate obj, sink, context, arrayList
    json = JSON.stringify dObj, null, 2
    ok = await sink uuid, json
    return Promise.resolve uuid

exports.Sansa = Sansa

#----------------------------------------------------------------------
# end of Sansa.coffee
