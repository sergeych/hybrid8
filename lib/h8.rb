require 'h8/version'
require 'h8/context'
require 'h8/value'
require 'h8/errors'
require 'h8/tools'
require 'h8/coffee'

# The native library should be required AFTER ruby defintions
require 'h8/h8'

# Initialize dependencies
H8::Coffee.compile ''
