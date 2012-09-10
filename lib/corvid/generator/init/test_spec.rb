require 'corvid/generator/base'

class Corvid::Generator::InitTestSpec < ::Corvid::Generator::Base
  namespace 'init:test'

  desc 'spec', 'Adds support for specifications.'
  declare_option_to_run_bundle_at_exit(self)
  def spec
    install_feature builtin_plugin, 'test_spec', run_bundle_at_exit: true
  end
end
