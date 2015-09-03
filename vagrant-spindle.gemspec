# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'spindle/version'

Gem::Specification.new do |spec|
  spec.name          = "vagrant-spindle"
  spec.version       = Vagrant::Spindle::VERSION
  spec.authors       = ["Anssi Syrjäsalo"]
  spec.email         = ["anssi.syrjasalo@gmail.com"]
  spec.summary       = %q{Vagrant continuous file syncer plugin.}
  spec.description   = %q{Uses filesystem events and rsync. Works on GNU/Linux, OS X and Windows.}
  spec.homepage      = "https://github.com/asyrjasalo/vagrant-spindle"
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", '1.10.5'
  spec.add_development_dependency "rake"
end
