# sansaFsTest.coffee
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
sansa = require '../lib/sansa'
sansaFs = require '../lib/sansa-fs'

describe "sansa-fs (File System)", ->
  it "gets exported by sansa", ->
    should.exist sansa.connect.fs
    should.exist sansa.connect.fs.input
    should.exist sansa.connect.fs.output

  it "can be used to create a jsonSource", ->
    jsonInput = sansa.connect.fs.input "/tmp"
    jsonInput.should.be.ok

  it "can be used to create a jsonSink", ->
    jsonOutput = sansa.connect.fs.output "/tmp"
    jsonOutput.should.be.ok

  describe "mocking", ->
    it "can be mocked", ->
      sansaFs.testWith {}
      sansaFs.testWith
        options: {}
  
  describe "input", ->
    it "returns null when the file doesn't exist", ->
      sansaFs.testWith
        fs:
          existsSync: (name) -> false
      {input} = sansaFs
      jsonInput = input "/tmp"
      result = jsonInput '0f502b8e-f753-4e06-95c2-9a66f9415447'
      should.not.exist result

    it "attempts to read the when it does exist", (done) ->
      sansaFs.testWith
        fs:
          existsSync: (name) -> true
          readFileSync: (name, options) -> done()
      {input} = sansaFs
      jsonInput = input "/tmp"
      result = jsonInput '0f502b8e-f753-4e06-95c2-9a66f9415447'

    it "uses the provided directory as a base directory", (done) ->
      sansaFs.testWith
        fs:
          existsSync: (name) -> true
          readFileSync: (name, options) -> "{}"
        path:
          join: (dir, file) ->
            done() if dir is "/tmp"
      {input} = sansaFs
      jsonInput = input "/tmp"
      result = jsonInput '0f502b8e-f753-4e06-95c2-9a66f9415447'

  describe "output", ->
    it "uses the provided directory as a base directory", (done) ->
      sansaFs.testWith
        fs:
          writeFile: (path, json, options, callback) -> true
        path:
          join: (dir, file) ->
            done() if dir is "/tmp"
      {output} = sansaFs
      jsonOutput = output "/tmp"
      result = jsonOutput '0f502b8e-f753-4e06-95c2-9a66f9415447', '{}'

    it "throws an error if it encounters an error", (done) ->
      sansaFs.testWith
        fs:
          writeFile: (path, json, options, callback) ->
            callback "Exterminate! Exterminate!"
      {output} = sansaFs
      jsonOutput = output "/tmp"
      try
        result = jsonOutput '0f502b8e-f753-4e06-95c2-9a66f9415447', '{}'
      catch err
        done() if err is "Exterminate! Exterminate!"

    it "calls the callback with null if there is no error", (done) ->
      sansaFs.testWith
        fs:
          writeFile: (path, json, options, callback) -> callback null
      {output} = sansaFs
      jsonOutput = output "/tmp"
      options =
        encoding: 'utf8'
      result = jsonOutput '0f502b8e-f753-4e06-95c2-9a66f9415447', '{}'
      done()

#----------------------------------------------------------------------
# end of sansaFsTest.coffee
