require 'corvid/generators/base'

class Corvid::Generator::NewUnitTest < ::Corvid::Generator::Base
  namespace 'new:test'

  argument :name, type: :string

  desc 'unit', 'Generates a new unit test.'
  def unit
    validate_requirements! 'corvid:test_unit'
    with_latest_resources(builtin_plugin) {
      template2 'test/unit/%src%_test.rb.tt', :src
    }
  end

  # Template vars
  private
  def src; name.underscore.gsub /^[\\\/]+|\.rb$/, '' end
  def bootstrap_dir; '../'*src.split(/[\\\/]+/).size + 'bootstrap' end
  def testcase_name; src.split(/[\\\/]+/).last.camelcase end
  def subject; src.camelcase end
end