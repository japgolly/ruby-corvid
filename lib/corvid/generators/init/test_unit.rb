require 'corvid/generators/base'

class Corvid::Generator::InitTestUnit < ::Corvid::Generator::Base
  namespace 'init:test'

  desc 'unit', 'Adds support for unit tests.'
  declare_option_to_run_bundle(self)
  def unit
    install_feature builtin_plugin, 'test_unit', run_bundle: true
  end
end
