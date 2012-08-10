require 'corvid/constants'
require 'corvid/feature_registry'
require 'corvid/generators/update'
require 'corvid/res_patch_manager'
require 'corvid/test/helpers/plugins'
require 'golly-utils/testing/rspec/arrays'
require 'golly-utils/testing/rspec/files'
require 'yaml'

module Corvid
  module ResourcePatchTests
    include PluginTestHelpers

    # @!visibility private
    def self.included(base)
      base.extend ClassMethods
    end

    module ClassMethods
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

      def include_feature_update_install_tests(features)
        latest_resource_version= rpm.latest_version
        feature_registry= Corvid::FeatureRegistry
        tests= features.map {|name|
                 f= feature_registry.instance_for(name)
                 unless f.since_ver == latest_resource_version
                   %[
                     it("Testing feature: #{name}"){
                       @rpm= rpm
                       test_feature_updates_match_install '#{name}', #{f.since_ver}
                     }
                   ]
                 end
               }.compact
        unless tests.empty?
          class_eval <<-EOB
            describe 'Feature Installers: Update vs Install' do
              run_each_in_empty_dir
              #{tests * "\n"}
            end
          EOB
        end
      end

      def res_patch_dir(dir)
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
        def install(feature, ver=nil)
          ver ||= rpm.latest_version
          # Hardcoded-logic here but all features apart from corvid, requrie corvid to be installed first.
          unless feature == 'corvid'
            Dir.mkdir '.corvid' unless Dir.exists?('.corvid')
            File.write Corvid::Constants::VERSION_FILE, ver
            File.write Corvid::Constants::FEATURES_FILE, %w[corvid].to_yaml
          end
          with_resources(ver) {
            feature_installer!(feature).install
            add_feature feature
          }
          File.delete Corvid::Constants::VERSION_FILE if File.exists?(Corvid::Constants::VERSION_FILE)
        end
      }
    end

    # @!visibility private
    def test_feature_updates_match_install(feature, starting_version=1)
      # Install latest
      Dir.mkdir 'install'
      Dir.chdir 'install' do
        #run_generator TestInstaller, "install #{feature}"
        quiet_generator(TestInstaller).install feature
      end

      # Install old and upgrade
      Dir.mkdir 'upgrade'
      Dir.chdir 'upgrade' do
        quiet_generator(TestInstaller).install feature, starting_version
        quiet_generator(Corvid::Generator::Update).send :upgrade!, starting_version, @rpm.latest_version, [feature]
        File.delete Corvid::Constants::VERSION_FILE
      end

      # Compare directories
      files= get_files('upgrade')
      files.should equal_array get_files('install')
      get_dirs('upgrade').should equal_array get_dirs('install')
      files.each do |f|
        File.read("upgrade/#{f}").should == File.read("install/#{f}")
      end
    end

  end
end
