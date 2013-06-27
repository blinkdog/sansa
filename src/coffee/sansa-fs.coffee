# sansa-fs.coffee
# Copyright 2013 Patrick Meade. All rights reserved.
#----------------------------------------------------------------------

fs = require 'fs'
path = require 'path'

options =
  encoding: 'utf8'

exports.input = (directory) ->
  return (uuid) ->
    jsonPath = path.join directory, uuid
    if fs.existsSync jsonPath
      return fs.readFileSync jsonPath, options
    return null

exports.output = (directory) ->
  return (uuid, json, dObj, sObj) ->
    jsonPath = path.join directory, uuid
    fs.writeFile jsonPath, json, options, (err) ->
      throw err if err

#----------------------------------------------------------------------
# end of sansa-fs.coffee
