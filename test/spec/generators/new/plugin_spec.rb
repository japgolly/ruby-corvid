# encoding: utf-8
require_relative '../../../spec_helper'
require 'corvid/generators/new/plugin'

describe Corvid::Generator::NewPlugin do
  describe 'new:plugin' do

    context "when corvid:plugin is installed" do
      run_all_in_empty_dir("my_thing") {
        copy_dynamic_fixture :bare
        add_feature! 'corvid:plugin'
        create_gemspec_file 'my_thing'
        run_generator described_class, 'plugin happy'
      }

      it("should create a plugin"){
        'lib/my_thing/happy_plugin.rb'.should be_file_with_contents(%r|module MyThing|)
          .and(%r|class HappyPlugin < Corvid::Plugin|)
          .and(%r|name 'happy'|)
          .and(%r|require_path 'my_thing/happy_plugin'|)
          .and(%r|feature_manifest|)
          .and(%r|resources_path|)
      }

      it("should create a plugin test"){
        'test/spec/happy_plugin_spec.rb'.should be_file_with_contents(%r|require 'my_thing/happy_plugin'|)
          .and(%r|describe MyThing::HappyPlugin do|)
          .and(%r|include Corvid::ResourcePatchTests|)
          .and(%r|include_resource_patch_tests|)
          .and(%r|include_feature_update_install_tests|)
      }

      it("should create a CLI"){
        'bin/happy'.should be_file_with_contents(%r|'my_thing/happy_plugin'|)
          .and(%r|MyThing::HappyPlugin|)
          .and(%r|require 'corvid/cli/plugin'|)
        File.executable?('bin/happy').should be_true
      }

      it("should register the CLI as an executable in the gemspec"){
        'my_thing.gemspec'.should be_file_with_content %r|gem.executable.*[^a-zA-Z/]happy|
      }
    end

    context "when corvid:plugin is not installed" do
      it("should fail"){
        inside_dynamic_fixture(:bare){
          expect{ run_generator described_class, 'plugin happy' }.to raise_error Corvid::RequirementValidator::UnsatisfiedRequirementsError
        }
      }
    end
  end
end
