# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'syncer/version'

Gem::Specification.new do |spec|
  spec.name          = "vagrant-syncer"
  spec.version       = Vagrant::Syncer::VERSION
  spec.authors       = ["Anssi Syrjäsalo"]
  spec.email         = ["anssi.syrjasalo@gmail.com"]
  spec.summary       = %q{Less resource-hog Vagrant rsync and rsync-auto}
  spec.description   = %q{Optimized rsync and rsync-auto for large file hierarchies.}
  spec.homepage      = "https://github.com/asyrjasalo/vagrant-syncer"
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler"
  spec.add_development_dependency "rake"
end
