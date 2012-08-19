# encoding: utf-8
require_relative '../../../spec_helper'
require 'corvid/generators/new/plugin'

describe Corvid::Generator::NewPlugin do
  describe 'new:plugin' do
    run_all_in_empty_dir {
      copy_dynamic_fixture :bare
      run_generator described_class, 'plugin happy'
    }

    it("should create a plugin"){
      'lib/corvid/happy_plugin.rb'.should be_file_with_contents(/class HappyPlugin < Corvid::Plugin/)
        .and(%r|name 'happy'|)
        .and(%r|require_path 'corvid/happy_plugin'|)
        .and(%r|feature_manifest|)
        .and(%r|resources_path|)
    }

    it("should create a plugin test"){
      'test/spec/happy_plugin_spec.rb'.should be_file_with_contents(%r|require 'corvid/happy_plugin'|)
        .and(%r|describe HappyPlugin do|)
        .and(%r|include Corvid::ResourcePatchTests|)
        .and(%r|include_resource_patch_tests|)
        .and(%r|include_feature_update_install_tests|)
    }

    it("should create a CLI"){
      'bin/happy'.should be_file_with_contents(%r|'corvid/happy_plugin'|)
        .and(%r|HappyPlugin|)
        .and(%r|require 'corvid/cli/plugin'|)
      File.executable?('bin/happy').should be_true
    }
  end
end
