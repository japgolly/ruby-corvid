# encoding: utf-8
require_relative '../../../spec_helper'
require 'corvid/generators/new/feature'
require 'corvid/generators/new/plugin'
require 'corvid/extension'

describe Corvid::Generator::NewFeature do
  describe 'new:feature' do
    context "with no client res-patches" do
      run_all_in_empty_dir {
        copy_dynamic_fixture :bare
        add_feature! 'corvid:plugin'
        run_generator Corvid::Generator::NewPlugin, 'plugin big'
        run_generator described_class, 'feature small'
      }

      it("should declare the feature as being since_ver 1"){
        'lib/corvid/small_feature.rb'.should be_file_with_contents /since_ver 1/
      }
    end

    context "with 2 mock client res-patches" do
      run_all_in_empty_dir {
        copy_dynamic_fixture :bare
        add_feature! 'corvid:plugin'
        Dir.mkdir 'resources'
        File.write 'resources/00001.patch', ''
        File.write 'resources/00002.patch', ''
        run_generator Corvid::Generator::NewPlugin, 'plugin big'
        run_generator described_class, 'feature small'
      }

      it("should create a feature"){
        'lib/corvid/small_feature.rb'.should be_file_with_contents(/class SmallFeature < Corvid::Feature/)
          .and(%r[require 'corvid/feature'])
      }

      it("should declare the feature as being since_ver 3"){
        'lib/corvid/small_feature.rb'.should be_file_with_contents /since_ver 3/
      }

      Corvid::Extension.callbacks.each do |ext_point|
        class_eval <<-EOB
          it("should include extension point in feature: #{ext_point}"){
            'lib/corvid/small_feature.rb'.should be_file_with_contents /#{ext_point}/
          }
        EOB
      end

      it("should create a feature installer"){
        'resources/latest/corvid-features/small.rb'.should be_file_with_contents /^install\s*{/
      }

      (Corvid::Generator::Base::FEATURE_INSTALLER_VALUES_DEFS +
       Corvid::Generator::Base::FEATURE_INSTALLER_CODE_DEFS).each do |name|
        class_eval <<-EOB
          it("should include in feature installer: #{name}"){
            'resources/latest/corvid-features/small.rb'.should be_file_with_contents /#{name}/
          }
        EOB
      end

      it("should add the feature to the plugin manifest"){
        'lib/corvid/big_plugin.rb'.should be_file_with_contents \
          /feature_manifest\s*\(\{\n\s+'small'\s*=>\s*\['corvid\/small_feature'\s*,\s*'::SmallFeature'\],\n/
      }

    end
  end
end
