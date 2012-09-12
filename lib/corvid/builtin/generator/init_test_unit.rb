require_relative 'base'

class Corvid::Builtin::Generator::InitTestUnit < ::Corvid::Generator::Base
  namespace 'init:test'

  desc 'unit', 'Adds support for unit tests.'
  declare_option_to_run_bundle_at_exit(self)
  def unit
    install_feature builtin_plugin, 'test_unit', run_bundle_at_exit: true
  end
end
