@.puts ?= ->
  # Do nothing if not set

@globalsIncluded = true

RubyGate.prototype.toJSON = ->
  src = @__to_json
  res = {}
  for key in src.keys()
    res[key] = src[key]
  res
