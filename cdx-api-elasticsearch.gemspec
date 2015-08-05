# coding: utf-8
lib = File.expand_path('../deps/cdx-api-elasticsearch/lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'cdx/api/elasticsearch/version'

Gem::Specification.new do |spec|
  spec.name          = "cdx-api-elasticsearch"
  spec.version       = Cdx::Api::Elasticsearch::VERSION
  spec.authors       = ["Ary Borenszweig"]
  spec.email         = ["aborenszweig@manas.com.ar"]
  spec.description   = %q{ElasticSearch based CDX API implementation}
  spec.summary       = %q{Provides an implementation of the CDX API based on an ElasticSearch backend}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = Dir['deps/cdx-api-elasticsearch/**/*']
  spec.executables   = spec.files.grep(%r{^deps/cdx-api-elasticsearch/bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^deps/cdx-api-elasticsearch/(test|spec|features)/})
  spec.require_paths = ["deps/cdx-api-elasticsearch/lib"]

  spec.add_runtime_dependency "activesupport"
  spec.add_dependency "elasticsearch"
  spec.add_dependency "cdx"

  spec.add_development_dependency "activesupport"
  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec"
  spec.add_development_dependency "pry-byebug"
  spec.add_development_dependency "pry-rescue"
  spec.add_development_dependency "pry-stack_explorer"
  spec.add_development_dependency "pry-clipboard"
end
