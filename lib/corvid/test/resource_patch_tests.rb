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

      def include_patch_validity_tests(&block)

        $__corvid_resource_test_p1_block= block

        class_eval <<-EOB
          describe "Patches" do
            run_each_in_empty_dir

            # Test that we can explode n->1 without errors being raised.
            it("should be reconstructable back to v1"){
              rpm.with_resource_versions 1 do |dir|
                b= $__corvid_resource_test_p1_block
                instance_exec dir, &b if b
              end
            }
          end
        EOB
      end

      # @param [Plugin|Hash<String,Array>] manifest Either a plugin instance or a feature manifest.
      # @see Plugin#feature_manifest
      def include_feature_update_install_tests(plugin_name, manifest_or_plugin)
        manifest= if manifest_or_plugin.is_a?(Plugin)
                    plugin= manifest_or_plugin
                    use_resources_path plugin.resources_path
                    plugin.feature_manifest
                  else
                    manifest_or_plugin
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

      def use_resources_path(dir)
        raise "Directory doesn't exist: #{dir}" unless Dir.exists? dir
        define_rpm Corvid::ResPatchManager.new(dir)
      end

      def define_rpm(value)
        # Safe to use a global here because a) this test is meant to be shared between corvid and plugin providing
        # projects and within the same project i dont foresee any reason for them to run twice, and b) i'm busy AND lazy.
        $corvid_respatch_test_rpm= value
      end

      def rpm
        $corvid_respatch_test_rpm
      end
    end

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
