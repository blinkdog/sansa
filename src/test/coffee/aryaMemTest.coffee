# aryaMemTest.coffee
# Copyright 2015 Patrick Meade.
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

should = require 'should'
{AryaMemory} = require '../lib/arya-mem'

describe "arya-mem", ->
  memA = null
  
  beforeEach ->
    memA = new AryaMemory()
    
  it "can be constructed", ->
    should.exist memA

  it "can store json output", (done) ->
    memA.output "11faa8f9-c87d-44df-90af-461c4a280c21", "{}", (err) ->
      done() if not err?

  it "can retrieve json input", (done) ->
    memA.output "11faa8f9-c87d-44df-90af-461c4a280c21", "{}", (err) ->
      throw err if err?
    memA.input "11faa8f9-c87d-44df-90af-461c4a280c21", (err, json) ->
      throw err if err?
      done() if json is "{}"

  it "has independent instances", (done) ->
    memB = new AryaMemory()
    memA.output "11faa8f9-c87d-44df-90af-461c4a280c21", "{}", (err) ->
      throw err if err?
    memB.input "11faa8f9-c87d-44df-90af-461c4a280c21", (err, json) ->
      throw err if err?
      done() if not json?

  it "will not throw if not provided with an output callback", (done) ->
    memA.output "11faa8f9-c87d-44df-90af-461c4a280c21", "{}"
    memA.input "11faa8f9-c87d-44df-90af-461c4a280c21", (err, json) ->
      throw err if err?
      done() if json is "{}"

#----------------------------------------------------------------------
# end of aryaMemTest.coffee
