require 'corvid/generators/base'

class Corvid::Generator::NewSpec < ::Corvid::Generator::Base
  namespace 'new:test'

  argument :name, type: :string

  desc 'spec', 'Generates a new specification.'
  def spec
    validate_requirements! 'corvid:test_spec'
    with_latest_resources(builtin_plugin) {
      template2 'test/spec/%src%_spec.rb.tt'
    }
  end

  # Template vars
  private
  def src; name.underscore.gsub /^[\\\/]+|\.rb$/, '' end
  def bootstrap_dir; '../'*src.split(/[\\\/]+/).size + 'bootstrap' end
  def testcase_name; src.split(/[\\\/]+/).last.camelcase end
  def subject; src.camelcase end
end
