# Cakefile
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

{exec} = require 'child_process'

task 'build', 'Build the library', ->
  compile -> test()

task 'clean', 'Remove build cruft', ->
  clean()

task 'compile', 'Compile CoffeeScript to JavaScript', ->
  compile()

task 'rebuild', 'Rebuild the library', ->
  clean -> compile -> test()
  
task 'test', 'Test with Jasmine specs', ->
  test()

clean = (callback) ->
  exec 'rm -fR lib/*', (err, stdout, stderr) ->
    throw err if err
#    console.log "Project cleaned"
    callback?()

compile = (callback) ->
  exec 'coffee -o lib/ -c src/coffee', (err, stdout, stderr) ->
    throw err if err
#    console.log "Compiled CoffeeScript src/coffee -> lib"
    callback?()

test = (callback) ->
  exec 'jasmine-node --verbose --noStack --coffee spec/', (err, stdout, stderr) =>
    console.log stdout + stderr
    if stdout.indexOf("Failures") >= 0
      throw "Failed: Jasmine Tests" 
    callback?()

#----------------------------------------------------------------------
# end of Cakefile
