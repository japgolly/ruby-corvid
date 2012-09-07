# encoding: utf-8
require File.expand_path('../lib/corvid/constants', __FILE__)

Gem::Specification.new do |gem|
  gem.name          = "corvid"
  gem.version       = Corvid::Constants::VERSION.dup
  gem.date          = Time.new.strftime '%Y-%m-%d'
  #gem.summary       = %q{TODO: Write a gem summary}
  #gem.description   = %q{TODO: Write a gem description}
  gem.authors       = ["David Barri"]
  gem.email         = ["japgolly@gmail.com"]
  gem.homepage      = "https://github.com/japgolly/corvid"

  gem.files         = `git ls-files`.split($\)
  gem.test_files    = gem.files.grep(/^test\//)
  gem.require_paths = %w[lib]
  gem.bindir        = 'bin'
  gem.executables   = %w[corvid]

  gem.add_runtime_dependency 'golly-utils'
  gem.add_runtime_dependency 'activesupport'
  gem.add_runtime_dependency 'thor', '~> 0.15.4'
  gem.add_development_dependency 'rspec'
  gem.add_development_dependency 'rake'
end
