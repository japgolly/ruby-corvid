require_relative 'base'

class Corvid::Builtin::Generator::NewUnitTest < ::Corvid::Generator::Base
  namespace 'new:test'

  argument :name, type: :string, desc: "The test name, or source file for which to generate a test."

  desc 'unit', 'Generates a new unit test.'
  def unit
    validate_requirements! 'corvid:test_unit'
    with_installed_resources(builtin_plugin) {
      template2 'test/unit/%src%_test.rb.tt'
    }
  end

  # Template vars
  private
  def src
    name.underscore
        .gsub(/^[\\\/]+|\.rb$/,'')
        .sub(/^lib[\\\/]+/,'')
        .sub(/^#{Regexp.quote project_name}[\\\/]+/,'')
        .sub(/_test$/,'')
  end
  def bootstrap_dir; '../'*src.split(/[\\\/]+/).size + 'bootstrap' end
  def testcase_name; src.split(/[\\\/]+/).last.camelcase end
  def subject; src.camelcase end
end
