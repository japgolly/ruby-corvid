require 'corvid/generators/base'

class Corvid::Generator::InitPlugin < ::Corvid::Generator::Base
  namespace 'init'

  desc 'plugin', 'Adds plugin development support.'
  declare_option_to_run_bundle_at_exit(self)
  def plugin
    install_feature builtin_plugin, 'plugin'
  end
end
