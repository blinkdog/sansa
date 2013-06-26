# Cakefile
# Copyright 2013 Patrick Meade. All rights reserved.
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
    if ~stdout.indexOf "Expected"
      console.log stdout + stderr
      throw "Failed: Jasmine Tests" 
    callback?()

#----------------------------------------------------------------------
# end of Cakefile
