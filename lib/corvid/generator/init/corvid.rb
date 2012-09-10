require 'corvid/generator/base'
require 'corvid/generator/init/test_unit'
require 'corvid/generator/init/test_spec'

class Corvid::Generator::InitCorvid < ::Corvid::Generator::Base

  desc 'init', 'Creates a new Corvid project in the current directory.'
  method_option :'test-unit', type: :boolean
  method_option :'test-spec', type: :boolean
  declare_option_to_run_bundle_at_exit(self)
  def init
    with_latest_resources(builtin_plugin) {|ver|
      with_action_context feature_installer!('corvid'), &:install
      write_client_versions builtin_plugin.name => ver
      add_plugin            builtin_plugin
      add_feature           feature_id_for(builtin_plugin.name,'corvid')

      invoke 'init:test:unit', [], RUN_BUNDLE => false if boolean_specified_or_ask :'test-unit', 'Add support for unit tests?'
      invoke 'init:test:spec', [], RUN_BUNDLE => false if boolean_specified_or_ask :'test-spec', 'Add support for specs?'

      run_bundle_at_exit()
    }
  end
end
