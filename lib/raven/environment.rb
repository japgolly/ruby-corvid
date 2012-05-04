RAVEN_ROOT= File.expand_path('../../..',__FILE__)
raise "Gemfile not found in Raven root: #{RAVEN_ROOT}" unless File.exists?("#{RAVEN_ROOT}/Gemfile")

$:.unshift "#{RAVEN_ROOT}/lib"
require 'raven/version'
