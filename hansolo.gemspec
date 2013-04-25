# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'hansolo/version'

Gem::Specification.new do |spec|
  spec.name          = "hansolo"
  spec.version       = Hansolo::VERSION
  spec.authors       = ["Brian Kaney"]
  spec.email         = ["brian@vermonster.com"]
  spec.description   = %q{Tool to automate deployment using chef-solo and berkshelf}
  spec.summary       = %q{Vendors Berkshelf cookbooks, uses rsync to sync cookbooks, and NET::SSH to run chef-solo with conventions for building solo.rb and the JSON runlist}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency "aws-sdk"
  spec.add_dependency "net-ssh"
  spec.add_dependency "net-ssh-gateway"
  spec.add_dependency "json"
  spec.add_dependency "terminal-table"

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "mocha"
end
