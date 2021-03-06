# coding: utf-8
lib = File.expand_path('../deps/cdx_core/lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'cdx/version'

Gem::Specification.new do |spec|
  spec.name          = "cdx"
  spec.version       = Cdx::VERSION
  spec.authors       = ["Mariano Abel Coca"]
  spec.email         = ["marianoabelcoca@gmail.com"]
  spec.summary       = %q{This gem contains CDX core fields specification}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = Dir['deps/cdx_core/**/*']
  spec.executables   = spec.files.grep(%r{^deps/cdx_core/bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^deps/cdx_core/(test|spec|features)/})
  spec.require_paths = ["deps/cdx_core/lib"]

  spec.add_dependency "activesupport"

  spec.add_development_dependency "bundler", "~> 1.7"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec"
  spec.add_development_dependency "pry-byebug"
  spec.add_development_dependency "pry-rescue"
  spec.add_development_dependency "pry-stack_explorer"
  spec.add_development_dependency "pry-clipboard"
end
