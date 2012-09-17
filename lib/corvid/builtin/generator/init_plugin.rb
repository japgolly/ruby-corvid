require_relative 'base'

class Corvid::Builtin::Generator::InitPlugin < ::Corvid::Generator::Base
  namespace 'init'

  desc 'plugin', 'Adds support for Corvid plugin development.'
  declare_option_to_run_bundle_at_exit(self)
  def plugin
    install_feature builtin_plugin, 'plugin'
  end
end
