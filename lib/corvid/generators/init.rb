require 'corvid/generators/base'
require 'yaml'

class Corvid::Generator::Init < Corvid::Generator::Base
  module InitHelpers
    def install_latest_ver_of_feature(name, run_bundle=true)
      with_latest_resources {|ver|
        feature_installer(name).install
        add_feature name
        yield ver if block_given?
        run_bundle() if run_bundle
      }
    end
  end
  include InitHelpers

  desc 'project', 'Creates a new Corvid project in the current directory.'
  method_option :'test-unit', type: :boolean
  method_option :'test-spec', type: :boolean
  run_bundle_option(self)
  def project
    install_latest_ver_of_feature('corvid') {|ver|
      create_file '.corvid/version.yml', ver.to_s, force: true

      invoke 'init:test:unit', [], RUN_BUNDLE => false if boolean_specified_or_ask :'test-unit', 'Add support for unit tests?'
      invoke 'init:test:spec', [], RUN_BUNDLE => false if boolean_specified_or_ask :'test-spec', 'Add support for specs?'
    }
  end

  class Test < Corvid::Generator::Base
    include InitHelpers

    desc 'unit', 'Adds support for unit tests.'
    run_bundle_option(self)
    def unit
      install_latest_ver_of_feature 'test_unit'
    end

    desc 'spec', 'Adds support for specifications.'
    run_bundle_option(self)
    def spec
      install_latest_ver_of_feature 'test_spec'
    end

  end # class Init::Test
end # class Init
