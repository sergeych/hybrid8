@.puts ?= ->
  # Do nothing if not set

@globalsIncluded = true

RubyGate.prototype.toJSON = ->
  JSON.parse @__to_json

Object.prototype.__rb_to_js = ->
  JSON.stringify @
