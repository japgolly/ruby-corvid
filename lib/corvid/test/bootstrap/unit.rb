Bundler.require :test_unit

require 'minitest/unit'
MiniTest::Unit.autorun

if ENV.on?('CI')
  ENV['CI_REPORTS'] ||= "#{APP_ROOT}/target/test-reports/unit"
  require 'ci/reporter/minitest'
  MiniTest::Unit.runner = CI::Reporter::Runner.new
end

require_if_available 'active_support/testing/assertions'

class MiniTest::Unit::TestCase
  include TestHelpers
  include ActiveSupport::Testing::Assertions if defined?(ActiveSupport::Testing::Assertions)
  include AssertDifference if defined?(AssertDifference)
end
