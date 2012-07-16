# encoding: utf-8

Gem::Specification.new do |gem|
  gem.name          = "mock_plugin"
  gem.version       = '0'
  gem.date          = Date.today.to_s

  gem.add_dependency 'corvid'

  #gem.files         = %w[mock_plugin.gemspec lib/corvid/plugins/mock_plugin.rb]
  gem.require_paths = %w[lib]
end
