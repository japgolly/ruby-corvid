require 'corvid/generators/base'
require 'corvid/builtin/builtin_plugin'
require 'yaml'

class Corvid::Generator::Init < ::Corvid::Generator::Base

  desc 'project', 'Creates a new Corvid project in the current directory.'
  method_option :'test-unit', type: :boolean
  method_option :'test-spec', type: :boolean
  declare_option_to_run_bundle(self)
  def project
    with_latest_resources {|ver|
      feature_installer!('corvid').install
      write_client_version ver
      add_plugin 'corvid', ::Corvid::Builtin::BuiltinPlugin.new
      add_feature 'corvid'

      invoke 'init:test:unit', [], RUN_BUNDLE => false if boolean_specified_or_ask :'test-unit', 'Add support for unit tests?'
      invoke 'init:test:spec', [], RUN_BUNDLE => false if boolean_specified_or_ask :'test-spec', 'Add support for specs?'

      run_bundle()
    }
  end

  desc 'plugin', 'Adds plugin development support.'
  declare_option_to_run_bundle(self)
  def plugin
    install_feature 'plugin'
  end

  class Test < ::Corvid::Generator::Base

    desc 'unit', 'Adds support for unit tests.'
    declare_option_to_run_bundle(self)
    def unit
      install_feature 'test_unit', run_bundle: true
    end

    desc 'spec', 'Adds support for specifications.'
    declare_option_to_run_bundle(self)
    def spec
      install_feature 'test_spec', run_bundle: true
    end

  end # class Init::Test
end # class Init
