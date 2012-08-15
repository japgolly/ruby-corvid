require 'corvid/generators/base'

class Corvid::Generator::InitTestSpec < ::Corvid::Generator::Base
  namespace 'init:test'

  desc 'spec', 'Adds support for specifications.'
  declare_option_to_run_bundle(self)
  def spec
    install_feature builtin_plugin, 'test_spec', run_bundle: true
  end
end
