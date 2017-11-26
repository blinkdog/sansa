# SansaMemory.coffee
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

class SansaMemory
  constructor: ->
    @_store = {}

  read: (uuid) =>
    # DEBUG: console.log "LOAD: #{uuid} -> #{@_store[uuid]}"
    return Promise.resolve @_store[uuid]

  write: (uuid, json) =>
    @_store[uuid] = json
    # DEBUG: console.log "SAVE: #{uuid} -> #{@_store[uuid]}"
    return Promise.resolve uuid

exports.SansaMemory = SansaMemory

#----------------------------------------------------------------------
# end of SansaMemory.coffee
