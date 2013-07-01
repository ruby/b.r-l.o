# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'redmine_link_to_root/version'

Gem::Specification.new do |spec|
  spec.name          = "redmine_link_to_root"
  spec.version       = RedmineLinkToRoot::VERSION
  spec.authors       = ["hsbt", "yugui"]
  spec.email         = ["shibata.hiroshi@gmail.com"]
  spec.description   = %q{}
  spec.summary       = %q{}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
end
