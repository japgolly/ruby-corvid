# encoding: utf-8
require File.expand_path('../lib/raven/version', __FILE__)

Gem::Specification.new do |gem|
  gem.name          = "raven"
  gem.version       = Raven::VERSION
  gem.date          = Date.today.to_s
  gem.summary       = %q{TODO: Write a gem summary}
  gem.description   = %q{TODO: Write a gem description}
  gem.authors       = ["David Barri"]
  gem.email         = ["japgolly@gmail.com"]
  #gem.homepage      = ""

  #gem.add_dependency 'thor'
  #gem.add_dependency 'activesupport'
  gem.add_development_dependency 'thor'
  gem.add_development_dependency 'activesupport'
  gem.add_development_dependency 'rspec'
  gem.add_development_dependency 'rake'

  gem.files         = `git ls-files`.split($\)
  gem.executables   = %w[raven]
  gem.require_paths = %w[lib]
  gem.test_files    = gem.files.grep(/^test\//)
end
