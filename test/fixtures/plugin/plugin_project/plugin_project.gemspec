# encoding: utf-8
require File.expand_path('../lib/plugin_project/version', __FILE__)

Gem::Specification.new do |gem|
  gem.name        = "plugin_project"
  gem.version     = PluginProject::VERSION.dup
  gem.date        = Time.new.strftime '%Y-%m-%d'
  #gem.summary     = %q{TODO: Write a gem summary}
  #gem.description = %q{TODO: Write a gem description}
  gem.authors     = ["David Barri"]
  gem.email       = ["japgolly@gmail.com"]
  #gem.homepage    = "https://github.com/username/plugin_project"

  gem.files         = File.exists?('.git') ? `git ls-files`.split($\) : \
                      Dir['**/*'].reject{|f| !File.file? f or %r!^(?:target|resources/latest)/! === f}.sort
  gem.test_files    = gem.files.grep(/^test\//)
  gem.require_paths = %w[lib]
  gem.bindir        = 'bin'
  gem.executables   = %w[p1]

  gem.add_runtime_dependency 'corvid'
end

