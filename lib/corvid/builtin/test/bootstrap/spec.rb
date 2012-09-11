Bundler.require :test_spec

if ENV.on?('CI')
  ENV['CI_REPORTS'] ||= "#{APP_ROOT}/target/test-reports/spec"
  require 'ci/reporter/rspec'
  RSpec.configure do |config|
    config.add_formatter CI::Reporter::RSpec
  end
end

RSpec.configure do |config|
  config.include TestHelpers
  # TODO merge this include stuff with unit. Should just be an array of shit to check n include and reuse in unit&spec
  config.include Mail::Matchers if defined?(Mail::Matchers)
  config.include Rack::Test::Methods if defined?(Rack::Test::Methods)
end
