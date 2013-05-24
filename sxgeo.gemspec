# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'sxgeo/version'

Gem::Specification.new do |gem|
  gem.name          = "sxgeo"
  gem.version       = Sxgeo::VERSION
  gem.authors       = ["nleo"]
  gem.description   = %q{Sypex Geo port}
  gem.summary       = gem.description
  gem.homepage      = "https://github.com/nleo/sxgeo"

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]
end
