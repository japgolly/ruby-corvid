require 'corvid/constants'
require 'corvid/feature_registry'
require 'corvid/generators/update'
require 'corvid/naming_policy'
require 'corvid/res_patch_manager'
require 'corvid/test/helpers/plugins'
require 'golly-utils/testing/rspec/arrays'
require 'golly-utils/testing/rspec/files'
require 'yaml'

module Corvid
  module ResourcePatchTests
    include PluginTestHelpers
    include Corvid::NamingPolicy

    # @!visibility private
    def self.included(base)
      base.extend ClassMethods
    end

    module ClassMethods
      include Corvid::NamingPolicy

      # Includes tests that assert the validity of resource patches.
      #
      # @param [nil,Proc] ver1_test_block An optional block of additional checks to run to confirm the exploded state of resources
      #   at version 1.
      # @yieldparam [String] dir The directory containing the exploded v1 resources.
      # @return [void]
      def include_patch_validity_tests(&ver1_test_block)

        $__corvid_resource_test_ver1_test_block= ver1_test_block

        class_eval <<-EOB
          describe "Patches" do
            run_each_in_empty_dir

            # Test that we can explode n->1 without errors being raised.
            it("should be reconstructable back to v1"){
              rpm.with_resource_versions 1 do |dir|
                b= $__corvid_resource_test_ver1_test_block
                instance_exec dir, &b if b
              end
            }
          end
        EOB
      end

      # Includes tests that confirm that for features provided, updating from the earliest available version gives the
      # same results as install the feature at the latest version. Any missing steps in `update` or `install` of the
      # feature installer will be caught here.
      #
      # @overload include_feature_update_install_tests(plugin)
      #   @param [Plugin] plugin A plugin instance.
      # @overload include_feature_update_install_tests(plugin_name, feature_manifest)
      #   @param [String] plugin_name The name of the plugin that provides the features.
      #   @param [Hash<String,Array>] feature_manifest A map of features to require path and class names.
      #   @see Plugin#feature_manifest
      # @return [void]
      def include_feature_update_install_tests(arg1, arg2=nil)
        plugin_name, manifest = nil,nil
        if arg2
          # args = plugin_name, feature_manifest
          plugin_name= arg1
          manifest= arg2
        else
          # args = plugin
          plugin= arg1
          plugin_name= plugin.name
          manifest= plugin.feature_manifest
          use_resources_path plugin.resources_path
        end
        features= manifest.keys

        latest_resource_version= rpm.latest_version
        feature_registry= ::Corvid::FeatureRegistry #.send :new - Generators need to use same instance. Easier to just set singleton and clear afterwards.
        feature_registry.use_feature_manifest plugin_name, manifest

        tests= features.map {|feature_name|
                 f= feature_registry.instance_for(feature_id_for(plugin_name, feature_name))
                 unless f.since_ver == latest_resource_version
                   %[
                     it("Testing feature: #{feature_name}"){
                       @rpm= rpm
                       test_feature_updates_match_install '#{plugin_name}', '#{feature_name}', #{f.since_ver}
                     }
                   ]
                 end
               }.compact
        unless tests.empty?
          class_eval <<-EOB
            describe 'Feature Installers: Update vs Install' do
              run_each_in_empty_dir
              #{tests * "\n"}
              after(:all){ ::Corvid::FeatureRegistry.clear_cache }
            end
          EOB
        end
      end

      # Specifies the path containing resource patches.
      #
      # @param [String] dir
      # @return [void]
      def use_resources_path(dir)
        raise "Directory doesn't exist: #{dir}" unless Dir.exists? dir
        define_rpm Corvid::ResPatchManager.new(dir)
      end

      # @!visibility private
      def define_rpm(value)
        # Safe to use a global here because a) this test is meant to be shared between corvid and plugin providing
        # projects and within the same project i dont foresee any reason for them to run twice, and b) i'm busy AND lazy.
        $corvid_respatch_test_rpm= value
      end

      # @return [nil,ResPatchManager]
      def rpm
        $corvid_respatch_test_rpm
      end
    end

    # @return [nil,ResPatchManager]
    def rpm
      @rpm ||= self.class.rpm
    end

    # @!visibility private
    class TestInstaller < Corvid::Generator::Base
      no_tasks{
        def install(plugin_name, feature_name, ver=nil)
          ver ||= rpm.latest_version
          feature_id= feature_id_for(plugin_name, feature_name)
          # Hardcoded-logic here but all features apart from corvid, requrie corvid to be installed first.
          corvid_feature_id= feature_id_for('corvid','corvid')
          unless feature_id == corvid_feature_id
            Dir.mkdir '.corvid' unless Dir.exists?('.corvid')
            File.write Corvid::Constants::VERSION_FILE, ver
            File.write Corvid::Constants::FEATURES_FILE, [corvid_feature_id].to_yaml
          end
          with_resources(ver) {
            feature_installer!(feature_name).install
            add_feature feature_id
          }
          File.delete Corvid::Constants::VERSION_FILE if File.exists?(Corvid::Constants::VERSION_FILE)
        end
      }
    end

    # @!visibility private
    def test_feature_updates_match_install(plugin_name, feature_name, starting_version=1)
      # Install latest
      Dir.mkdir 'install'
      Dir.chdir 'install' do
        quiet_generator(TestInstaller).install plugin_name, feature_name
      end

      # Install old and upgrade
      Dir.mkdir 'upgrade'
      Dir.chdir 'upgrade' do
        quiet_generator(TestInstaller).install plugin_name, feature_name, starting_version
        quiet_generator(Corvid::Generator::Update).send :upgrade!, starting_version, @rpm.latest_version, [feature_id_for(plugin_name, feature_name)]
        File.delete Corvid::Constants::VERSION_FILE
      end

      # Compare directories
      files= get_files('upgrade')
      files.should equal_array get_files('install')
      get_dirs('upgrade').should equal_array get_dirs('install')
      files.each do |f|
        "upgrade/#{f}".should be_file_with_contents File.read("install/#{f}")
      end
    end

  end
end
