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
      def include_resource_patch_tests(plugin_or_dir = subject.(), &ver1_test_block)
        resources_path= plugin_or_dir.is_a?(Plugin) ? plugin_or_dir.resources_path : plugin_or_dir
        $include_resource_patch_tests_ver1_test_block= ver1_test_block

        class_eval <<-EOB
          describe "Resource Patches", slow: true do
            run_each_in_empty_dir

            # Test that we can explode n->1 without errors being raised.
            it("should be reconstructable back to v1"){
              rpm= ::Corvid::ResPatchManager.new #{resources_path.inspect}
              rpm.with_resource_versions 1 do |dir|
                b= $include_resource_patch_tests_ver1_test_block
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
      # TODO
      # @overload include_feature_update_install_tests(plugin)
      #   @param [Plugin] plugin A plugin instance.
      # @overload include_feature_update_install_tests(plugin_name, feature_manifest)
      #   @param [String] plugin_name The name of the plugin that provides the features.
      #   @param [Hash<String,Array>] feature_manifest A map of features to require path and class names.
      #   @see Plugin#feature_manifest
      # @return [void]
      def include_feature_update_install_tests(plugin = subject.(), features=nil)
        features ||= plugin.feature_manifest.keys
        latest_resource_version= Corvid::ResPatchManager.new(plugin.resources_path).latest_version

        $include_feature_update_install_tests_plugin= plugin
        Corvid::FeatureRegistry.use_feature_manifest_from(plugin)

        tests= features.map {|feature_name|
                 f= FeatureRegistry.instance_for(feature_id_for(plugin.name, feature_name))
                 unless f.since_ver == latest_resource_version
                   %[
                     it("Testing feature: #{feature_name}"){
                       Corvid::PluginRegistry.use_plugin $include_feature_update_install_tests_plugin
                       Corvid::FeatureRegistry.use_feature_manifest_from $include_feature_update_install_tests_plugin
                       test_feature_updates_match_install '#{plugin.name}', '#{feature_name}', #{f.since_ver}
                     }
                   ]
                 end
               }.compact
        unless tests.empty?
          class_eval <<-EOB
            describe 'Feature Installers: Update vs Install', slow: true do
              run_each_in_empty_dir
              #{tests * "\n"}
              after(:all){
                Corvid::FeatureRegistry.clear_cache
                Corvid::PluginRegistry.clear_cache
              }
            end
          EOB
        end
      end
    end

    # @!visibility private
    class TestInstaller < Corvid::Generator::Base
      no_tasks{
        include Corvid::PluginTestHelpers

        def install(plugin, feature_name, ver=nil)
          ver ||= rpm_for(plugin).latest_version
          feature_id= feature_id_for(plugin.name, feature_name)
          # TODO Hardcoded-logic here but all features apart from corvid, requrie corvid to be installed first.
          corvid_feature_id= feature_id_for('corvid','corvid')
          unless feature_id == corvid_feature_id
            Dir.mkdir '.corvid' unless Dir.exists?('.corvid')
            add_plugin! 'corvid'
            add_feature! corvid_feature_id
            add_version! 'corvid', ver
          end
          with_resources(plugin, ver) {
            with_action_context feature_installer!(feature_name), &:install
            add_feature feature_id
            add_version plugin, ver
          }
        end
      }
    end

    # @!visibility private
    def test_feature_updates_match_install(plugin_or_name, feature_name, starting_version=1)
      plugin= plugin_or_name.is_a?(Plugin) ? plugin_or_name : ::Corvid::PluginRegistry.instance_for(plugin_or_name)
      Dir.stub pwd: '/tmp/pwd_stub'

      # Install latest
      Dir.mkdir 'install'
      Dir.chdir 'install' do
        quiet_generator(TestInstaller).install plugin, feature_name
      end

      # Install old and upgrade
      Dir.mkdir 'upgrade'
      Dir.chdir 'upgrade' do
        quiet_generator(TestInstaller).install plugin, feature_name, starting_version
        g= quiet_generator(Corvid::Generator::Update)
        rpm= g.rpm_for(plugin)
        rpm.patch_exe += ' --quiet'
        g.send :upgrade!, plugin, starting_version, rpm.latest_version, [feature_name]
      end

      # Compare directories
      files= get_files('upgrade')
      files.should equal_array get_files('install')
      get_dirs('upgrade').should equal_array get_dirs('install')
      files.each do |f|
        next if f == '.corvid/versions.yml'
        "upgrade/#{f}".should be_file_with_contents File.read("install/#{f}")
      end
    end

  end
end
