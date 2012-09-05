# encoding: utf-8
require File.expand_path('../lib/client_project/version', __FILE__)

Gem::Specification.new do |gem|
  gem.name        = "client_project"
  gem.version     = ClientProject::VERSION.dup
  gem.date        = Date.today.to_s
  #gem.summary     = %q{TODO: Write a gem summary}
  #gem.description = %q{TODO: Write a gem description}
  gem.authors     = ["David Barri"]
  gem.email       = ["japgolly@gmail.com"]
  #gem.homepage    = "https://github.com/username/client_project"

  gem.add_runtime_dependency 'corvid'

  gem.files         = File.exists?('.git') ? `git ls-files`.split($\) : \
                      Dir['**/*'].reject{|f| !File.file? f or %r!^(?:target|resources/latest)/! === f}.sort
  gem.require_paths = %w[lib]
  gem.test_files    = gem.files.grep(/^test\//)
end

