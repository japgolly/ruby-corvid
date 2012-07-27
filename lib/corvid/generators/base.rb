require 'corvid/environment'
require 'corvid/res_patch_manager'

require 'active_support/core_ext/string/inflections'
require 'active_support/inflections'
require 'golly-utils/delegator'
require 'thor'
require 'yaml'

module Corvid
  module Generator

    # @abstract
    class Base < Thor
      include Thor::Actions
      RUN_BUNDLE= :'run_bundle'
      VERSION_FILE= '.corvid/version.yml'
      FEATURES_FILE= '.corvid/features.yml'

      def self.inherited(c)
        c.class_eval <<-EOB
          def self.source_root; $corvid_global_thor_source_root end
          namespace ::Thor::Util.namespace_from_thor_class(self).sub(/^corvid:generator:/,'')
        EOB
      end

      # This stops Thor thinking the public methods below are tasks
      no_tasks {

        def rpm=(rpm) @rpm= rpm end
        def rpm()     @rpm ||= ::Corvid::ResPatchManager.new end

        def get_installed_features
          if File.exists? FEATURES_FILE
            v= YAML.load_file FEATURES_FILE
            raise "Invalid #{FEATURES_FILE}. Array expected but got #{v.class}." unless v.is_a?(Array)
            v
          else
            nil
          end
        end

        def read_deployed_corvid_version
          if File.exists?(VERSION_FILE)
            v= YAML.load_file(VERSION_FILE)
            raise "Invalid version: #{v.inspect}\nNumber expected. Check your #{VERSION_FILE}." unless v.is_a? Fixnum
            v
          else
            nil
          end
        end
      }

      protected

      def res_dir
        $corvid_global_thor_source_root || raise("Resources haven't been deployed yet. Call with_latest_resources() first.")
      end

      def with_latest_resources(&block)
        with_resources :latest, &block
      end

      def with_resources(ver, &block)
        raise "Version can't be nil." if ver.nil?
        ver= rpm.get_latest_res_patch_version if ver == :latest
        raise "TODO Doco. This should never occur." if @@with_resource_version and ver != @@with_resource_version

        @@with_resource_depth += 1
        begin
          # Run locally if resources already available
          if @@with_resource_depth > 1
            return block.call(ver)
          end

          # Acquire resources and yield
          @@with_resource_version= with_resource_version
          rpm.with_resources(ver) do |resdir|
            $corvid_global_thor_source_root= resdir
            return block.call(ver)
          end

        ensure
          # Clean up when done
          if (@@with_resource_depth -= 1) == 0
            $corvid_global_thor_source_root= nil
            @@with_resource_version= nil
          end
        end
      end
      @@with_resource_depth= 0
      @@with_resource_version= nil
      def with_resource_version; @@with_resource_version end

      def self.run_bundle_option(t)
        t.method_option RUN_BUNDLE => true
      end

      def run_bundle
        if options[RUN_BUNDLE] and !$corvid_bundle_install_at_exit_installed
          $corvid_bundle_install_at_exit_installed= true
          at_exit{ run "bundle install" }
        end
      end

      def copy_file_unless_exists(src, tgt=nil, options={})
        tgt ||= src
        copy_file src, tgt, options unless File.exists?(tgt)
      end

      def boolean_specified_or_ask(option_name, question)
        v= options[option_name.to_sym]
        v or v.nil? && yes?(question + ' [yn]')
      end

      def copy_executable(name, *extra_args)
        copy_file name, *extra_args
        chmod name, 0755, *extra_args
      end

      def add_features(*features)
        # Read currently installed features
        installed= get_installed_features || []
        size_before= installed.size

        # Add features
        features.flatten.each do |feature|
          installed<< feature unless installed.include?(feature)
        end

        # Write back to disk
        if installed.size != size_before
          create_file FEATURES_FILE, installed.to_yaml, force: true
        end
      end
      alias :add_feature :add_features

      def feature_installer(feature)
        code= File.read("#{res_dir}/corvid-features/#{feature}.rb")
        d= GollyUtils::Delegator.new self, allow_protected: true
        d.instance_eval code
        d
      end

    end
  end
end
