# sansa-fs.coffee
# Copyright 2013 Patrick Meade.
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
