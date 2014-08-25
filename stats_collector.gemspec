# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'stats_collector/version'

Gem::Specification.new do |spec|
  spec.name          = 'stats_collector'
  spec.version       = StatsCollector::VERSION
  spec.authors       = ["Aaron OConnell"]
  spec.email         = ["aaron.oconnell@gmail.com"]
  spec.description   = %q{Collect, batch, and send stats}
  spec.summary       = %q{Stat Collector}
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency 'bundler', '~> 1.3'
  spec.add_development_dependency 'rake'
  spec.add_runtime_dependency 'rest-client', '~> 1.6'
end
