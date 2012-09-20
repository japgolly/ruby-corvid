require 'corvid/constants'
require 'corvid/feature_registry'
require 'corvid/generator/update'
require 'corvid/naming_policy'
require 'corvid/res_patch_manager'
require 'corvid/requirement_validator'
require 'corvid/builtin/test/helpers/plugins'
require 'golly-utils/ruby_ext/options'
require 'golly-utils/testing/rspec/arrays'
require 'golly-utils/testing/rspec/files'
require 'yaml'

module Corvid::Builtin
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
        resources_path= plugin_or_dir.is_a?(Corvid::Plugin) ? plugin_or_dir.resources_path : plugin_or_dir
        ba= ($include_resource_patch_tests_ver1_test_block ||= [])
        ba<< ver1_test_block

        class_eval <<-EOB
          describe "Resource Patches", slow: true do
            run_each_in_empty_dir

            # Test that we can explode n->1 without errors being raised.
            it("should be reconstructable back to v1"){
              rpm= ::Corvid::ResPatchManager.new #{resources_path.inspect}
              rpm.with_resource_versions 1 do |dir|
                b= $include_resource_patch_tests_ver1_test_block[#{ba.size-1}]
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
      # @param [Plugin|Class<Plugin>] plugin The plugin instance or class, that contains the features to be tested.
      # @param [Hash] options
      # @option options [Array<String>] :features (plugin.feature_manifest.keys)
      #   The names (not ids) of features to test.
      # @option options [nil|false|String] :context ("Feature Installers: Update vs Install")
      #   The title of the `describe` block that will house the tests, or `nil`/`false` to use the current context and
      #   not create a new one.
      # @return [void]
      def include_feature_update_tests(plugin = subject.(), options={})
        plugin= plugin.new if plugin.is_a?(Class)
        options.validate_option_keys :features, :context
        features= options[:features] || plugin.feature_manifest.keys
        ctx= options.has_key?(:context) ? options[:context] : 'Feature Installers: Update vs Install'
        ctx_start,ctx_end = ctx ? ["describe #{ctx.inspect}, slow: true do","end"] : ['','']
        latest_resource_version= Corvid::ResPatchManager.new(plugin.resources_path).latest_version

        pa= ($include_feature_update_tests_plugin ||= [])
        pa<< plugin
        Corvid::FeatureRegistry.clear_cache.register_features_in(plugin)

        tests= features.map {|feature_name|
                 f= Corvid::FeatureRegistry.instance_for(feature_id_for(plugin.name, feature_name))
                 unless f.since_ver == latest_resource_version
                   %[
                     it("Testing feature: #{feature_name}"){
                       p= $include_feature_update_tests_plugin[#{pa.size-1}]
                       Corvid::PluginRegistry.clear_cache.register p
                       Corvid::FeatureRegistry.clear_cache.register_features_in p
                       test_feature_updates_match_install '#{plugin.name}', '#{feature_name}', #{f.since_ver}
                     }
                   ]
                 end
               }.compact
        unless tests.empty?
          class_eval <<-EOB
            #{ctx_start}
              run_each_in_empty_dir
              #{tests * "\n"}
              after(:all){
                Corvid::FeatureRegistry.clear_cache
                Corvid::PluginRegistry.clear_cache
              }
            #{ctx_end}
          EOB
        end
      end
    end

    # @!visibility private
    class TestInstaller < Corvid::Generator::Base
      no_tasks{
        include Corvid::Builtin::PluginTestHelpers

        def install(plugin, feature_name, ver=nil)
          new_options= options.merge(RUN_BUNDLE => false)
          stub options: new_options

          ver ||= rpm_for(plugin).latest_version
          feature_id= feature_id_for(plugin.name, feature_name)

          Dir.mkdir '.corvid' unless Dir.exists?('.corvid')
          with_resources(plugin, ver) {
            fi= feature_installer!(feature_name)

            # Satisfy feature's requirements
            satisfy_requirements plugin, fi, ver

            # Pretend this plugin already installed
            add_plugin! plugin
            add_version plugin, ver

            # Install feature
            override_installed_features(plugin.name){
              @feature_being_installed= feature_name
              with_action_context fi, &:install
            }
            @feature_being_installed= nil
            add_feature feature_id
          }

          # Alternate way of installing feature, but with uncontrollable side effects as method futher evolves...
          #install_feature plugin, feature_name, run_bundle_at_exit: false
        end
      }
      protected
      def configure_new_rpm(rpm)
        rpm.patch_cmd += ' --quiet'
      end

      def satisfy_requirements(plugin, fi, ver)
        return unless fi.respond_to?(:requirements)
        prereq_features_to_install= []

        # Process each requirement
        rv= ::Corvid::RequirementValidator.new
        rv.add fi.requirements
        rv.requirements.each do |r|

          # Satisfy required plugin
          if p= r[:plugin]
            add_plugin! p
            v= plugin.name == p && ver
            add_version! p, (v || 1)
          end

          # Satisfy required feature
          if f_id= r[:feature_id]
            p,f = split_feature_id(f_id)
            if plugin.name == p
              # Same plugin: install for real
              prereq_features_to_install<< f unless features_installed_for_plugin(plugin).include? f
            else
              # Diff plugin: pretend it's installed
              add_feature! f_id
            end
          end
        end

        # Install required features from this plugin
        prereq_features_to_install.each{|f| install plugin, f, ver }
      end
    end

    # @!visibility private
    def test_feature_updates_match_install(plugin_or_name, feature_name, starting_version=1)
      plugin= plugin_or_name.is_a?(Corvid::Plugin) ? plugin_or_name : ::Corvid::PluginRegistry.instance_for(plugin_or_name)
      Dir.stub pwd: '/tmp/pwd_stub'

      # Install latest
      Dir.mkdir 'install'
      Dir.chdir 'install' do
        quiet_generator(TestInstaller).install plugin, feature_name
        feature_update_test__post_install(feature_name)
      end

      # Install old and update
      Dir.mkdir 'update'
      Dir.chdir 'update' do
        quiet_generator(TestInstaller).install plugin, feature_name, starting_version
        feature_update_test__pre_update(feature_name, starting_version)

        g= quiet_generator(Corvid::Generator::Update)
        rpm= g.rpm_for(plugin)
        rpm.patch_cmd += ' --quiet'
        rpm.stub interactive_patching?: false
        features= g.features_installed_for_plugin(plugin)
        g.send :update!, plugin, starting_version, rpm.latest_version, features
        feature_update_test__post_update(feature_name, rpm.latest_version)
      end

      # Compare directories
      files= get_files('update')
      files.should equal_array get_files('install')
      get_dirs('update').should equal_array get_dirs('install')
      files.each do |f|
        next if f == '.corvid/versions.yml'
        File.read("update/#{f}").should == File.read("install/#{f}")
      end
    end

    # Callback invoked just after installing the latest version in tests created by {#include_feature_update_tests}.
    # What has been generated here will be used to verify that updates work.
    #
    # @param [String] feature_name The feature currently being tested.
    # @return [void]
    def feature_update_test__post_install(feature_name)
    end

    # Callback invoked just before starting an update in tests created by {#include_feature_update_tests}.
    #
    # @param [String] feature_name The feature currently being tested.
    # @param [Fixnum] version The current version of the installation.
    # @return [void]
    def feature_update_test__pre_update(feature_name, version)
    end

    # Callback invoked just after performing an update in tests created by {#include_feature_update_tests}.
    #
    # @param [String] feature_name The feature currently being tested.
    # @param [Fixnum] version The current version of the installation.
    # @return [void]
    def feature_update_test__post_update(feature_name, version)
    end

  end
end
