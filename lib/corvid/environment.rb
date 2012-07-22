CORVID_ROOT ||= File.expand_path('../../..',__FILE__)
raise "Gemfile not found in Corvid root: #{CORVID_ROOT}" unless File.exists?("#{CORVID_ROOT}/Gemfile")

$:.unshift "#{CORVID_ROOT}/lib"
require 'corvid/version'
require 'golly-utils/ruby_ext/env_helpers'
