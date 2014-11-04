# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'h8/version'

Gem::Specification.new do |spec|
  spec.name          = "h8"
  spec.version       = H8::VERSION
  spec.authors       = ["sergeych"]
  spec.email         = ["sergeych"]
  spec.summary       = %q{Minimalistic and sane v8 bindings}
  spec.description   = %q{Should be more or less replacement for broken therubyracer gem and riny 2.1+ }
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.6"
  spec.add_development_dependency "rake"

  spec.add_dependency 'libv8'
end
