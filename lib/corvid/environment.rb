CORVID_ROOT ||= File.expand_path('../../..',__FILE__)
raise "Gemfile not found in Corvid root: #{CORVID_ROOT}" unless File.exists?("#{CORVID_ROOT}/Gemfile")

require 'bundler/setup'

require 'golly-utils/ruby_ext/env_helpers'
require 'corvid/plugin_manager'
