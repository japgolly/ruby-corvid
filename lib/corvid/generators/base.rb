require 'corvid/environment'
require 'corvid/res_patch_manager'
require 'corvid/generators/actions'

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
      include ActionExtentions

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

        # TODO Get vs read
        # TODO Installed vs deployed
        def get_installed_features
          if File.exists? FEATURES_FILE
            v= YAML.load_file FEATURES_FILE
            raise "Invalid #{FEATURES_FILE}. Array expected but got #{v.class}." unless v.is_a?(Array)
            raise "Invalid #{FEATURES_FILE}. At least 1 feature expected but not defined." if v.empty?
            v
          else
            nil
          end
        end

        def get_installed_features!
          features= get_installed_features
          raise "File not found: #{FEATURES_FILE}\nYou must install Corvid first. Try corvid init:project." if features.nil?
          features
        end

        # Reads the version of deployed Corvid resources.
        #
        # @return [Fixnum, nil] The version number or `nil` if Corvid isn't installed yet.
        # @raise If Corvid is installed but the version file is not in the expected format.
        def read_deployed_corvid_version
          if File.exists?(VERSION_FILE)
            v= YAML.load_file(VERSION_FILE)
            raise "Invalid version: #{v.inspect}\nNumber expected. Check your #{VERSION_FILE}." unless v.is_a? Fixnum
            v
          else
            nil
          end
        end

        # Reads the version of deployed Corvid resources.
        #
        # @return [Fixnum] The version number. Will never return `nil`.
        # @raise If Corvid is not installed.
        def read_deployed_corvid_version!
          ver= read_deployed_corvid_version
          raise "File not found: #{VERSION_FILE}\nYou must install Corvid first. Try corvid init:project." if ver.nil?
          ver
        end
      }

      protected

      def res_dir
        $corvid_global_thor_source_root || raise("Resources haven't been deployed yet. Call with_latest_resources() first.")
      end

      def with_latest_resources(&block)
        with_resources :latest, &block
      end

      # TODO confirm this doco
      # @overload with_resources(dir, &block)
      #   @param [String] dir The directory where the resources can be found.
      #   @yieldparam [void]
      # @overload with_resources(ver, &block)
      #   @param [Fixnum, :latest] ver The version of resources to use.
      #   @yieldparam [Fixnum] ver The version of the resources being used.
      def with_resources(ver, &block)

        # Check args
        raise "Block required." unless block
        ver= rpm.latest_version if ver == :latest
        raise "Invalid version: #{ver.inspect}" unless ver.is_a?(String) or ver.is_a?(Fixnum)
        raise "Directory doesn't exist: #{ver}" if ver.is_a?(String) and !Dir.exists?(ver)
        if @@with_resource_version and ver != @@with_resource_version
          raise "Nested calls with different versions not supported. This should never occur; BUG!\nInitial: #{@@with_resource_version.inspect}\nProposed: #{ver.inspect}"
        end

        @@with_resource_depth += 1
        begin

          if @@with_resource_depth > 1
            # Run locally if already pointing at desired resources
            return block.call(ver)
          else
            # Prepare initial state
            setup_proc= lambda {|dir|
              @@with_resource_version= ver
              @source_paths= [dir]
              $corvid_global_thor_source_root= dir
            }

            if ver.is_a?(String)
              # Use existing resource dir
              setup_proc.call ver
              return block.call()
            else
              # Deploy resources via RPM
              rpm.with_resources(ver) {|dir|
                setup_proc.call dir
                return block.call(ver)
              }
            end
          end

        ensure
          # Clean up when done
          if (@@with_resource_depth -= 1) == 0
            $corvid_global_thor_source_root= nil
            @@with_resource_version= nil
            @source_paths= nil
          end
        end
      end

      def self.run_bundle_option(t)
        t.method_option RUN_BUNDLE, type: :boolean, default: true, optional: true
      end

      def run_bundle
        if options[RUN_BUNDLE] and !$corvid_bundle_install_at_exit_installed
          $corvid_bundle_install_at_exit_installed= true
          at_exit {
            ENV['BUNDLE_GEMFILE']= nil
            ENV['RUBYOPT']= nil
            run "bundle install"
          }
        end
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

      def feature_installer_file(dir = res_dir(), feature)
        "#{dir}/corvid-features/#{feature}.rb"
      end
      def feature_installer_file!(dir = res_dir(), feature)
        filename= feature_installer_file(dir, feature)
        raise "File not found: #{filename}" unless File.exists?(filename)
        filename
      end

      def feature_installer_code(dir = res_dir(), feature)
        file= feature_installer_file(dir, feature)
        file && File.read(file) # TODO encoding
      end
      def feature_installer_code!(dir = res_dir(), feature)
        code= feature_installer_code(dir, feature)
        code or (
          feature_installer_file!(dir, feature) # This will raise its own error if file not found
          raise "Unable to read feature installer code for '#{feature}'."
        )
      end

      def feature_installer(dir = res_dir(), feature)
        code= feature_installer_code(dir, feature)
        code && dynamic_installer(code, feature)
      end
      def feature_installer!(dir = res_dir(), feature)
        installer= feature_installer(dir, feature)
        installer or (
          feature_installer_file!(dir, feature) # This will raise its own error if file not found
          raise "Unable to create feature installer for '#{feature}'."
        )
      end

      def dynamic_installer(code, feature, ver=nil)
        d= GollyUtils::Delegator.new self, allow_protected: true
        add_dynamic_code! d, code, feature, ver
      end

      def add_dynamic_code!(obj, code, feature, ver=nil)
        orig_methods= obj.public_methods
        obj.instance_eval code
        new_methods= obj.public_methods - orig_methods

        errmsg_frag= "#{feature} installer"
        ver ||= @@with_resource_version
        errmsg_frag.prepend "v#{ver} of " if ver

        new_methods.each {|m|
          obj.instance_eval <<-EOB
            alias :__raw_#{m} :#{m}
            def #{m}(*args)
              __raw_#{m} *args
            rescue => e
              raise e.class, "Error executing #{m}() in #{errmsg_frag}.\\n#\{e.to_s}", e.backtrace
            end
          EOB
        }

        obj
      end

      def write_version(ver)
        rpm.validate_version! ver, 1
        create_file VERSION_FILE, ver.to_s, force: true
      end

      private
      @@with_resource_depth= 0
      @@with_resource_version= nil
    end
  end
end
