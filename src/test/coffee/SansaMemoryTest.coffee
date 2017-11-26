# SansaMemoryTest.coffee
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

should = require "should"
{SansaMemory} = require "../lib/SansaMemory"

TEST_UUID = "11faa8f9-c87d-44df-90af-461c4a280c21"

describe "SansaMemory", ->
  mem = null

  beforeEach ->
    mem = new SansaMemory()

  it "can be constructed", ->
    should.exist mem

  it "can store json output", ->
    (mem.write TEST_UUID, "{}").should.be.fulfilledWith TEST_UUID

  it "can retrieve json input", ->
    uuid = await mem.write TEST_UUID, "{}"
    (mem.read TEST_UUID).should.be.fulfilledWith "{}"

  it "has independent instances", ->
    otherMem = new SansaMemory()
    uuid = await mem.write TEST_UUID, "{}"
    (otherMem.read TEST_UUID).should.be.fulfilledWith undefined

#----------------------------------------------------------------------
# end of SansaMemoryTest.coffee
