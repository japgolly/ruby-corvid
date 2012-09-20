require 'corvid/environment'
require 'corvid/constants'
require 'corvid/feature_registry'
require 'corvid/plugin_registry'
require 'corvid/naming_policy'
require 'corvid/requirement_validator'
require 'corvid/res_patch_manager'
require 'corvid/generator/action_extensions'
require 'corvid/generator/template_vars'
require 'corvid/generator/thor_monkey_patches'

require 'active_support/core_ext/string/inflections'
require 'active_support/inflections'
require 'golly-utils/delegator'
require 'golly-utils/ruby_ext/classes_and_types'
require 'golly-utils/ruby_ext/options'
require 'thor'
require 'yaml'

module Corvid

  # Everything within this module directly relates to Thor generators.
  #
  # @see https://github.com/wycats/thor Thor project.
  # @see http://rdoc.info/github/wycats/thor Thor documentation.
  module Generator

    # Abstract Thor generator that adds support for Corvid specific functionality.
    #
    # @abstract
    class Base < Thor
      include Thor::Actions
      include ActionExtensions
      include TemplateVars
      include ::Corvid::NamingPolicy

      # Callbacks in feature installers that each take a block of code.
      FEATURE_INSTALLER_CODE_DEFS= %w[install update].map(&:freeze).freeze

      # Methods in feature installers that accept and store a single value, (i.e. declare attributes).
      FEATURE_INSTALLER_VALUES_DEFS= %w[requirements].map(&:freeze).freeze

      # @!visibility private
      def self.inherited(c)
        c.class_eval <<-EOB
          def self.source_root; $corvid_global_thor_source_root end
          namespace ::Thor::Util.namespace_from_thor_class(self).sub(/^corvid:generator:/,'')
        EOB
      end

      # This stops stupid Thor thinking the public methods below are tasks and issuing warnings
      # Not using no_tasks{} because it stops Yard seeing the methods.
      @no_tasks= true

      # @!attribute [rw] feature_registry
      #   @return [FeatureRegistry]
      ::Corvid::FeatureRegistry.def_accessor(self)

      # @!attribute [rw] plugin_registry
      #   @return [PluginRegistry]
      ::Corvid::PluginRegistry.def_accessor(self)

      # Returns a resource-patch manager configured to use the resources of a given plugin.
      #
      # @param [Plugin] plugin
      # @return [ResPatchManager]
      def rpm_for(plugin)
        @rpms ||= {}
        @rpms[plugin.name] ||= new_rpm_for(plugin)
      end

      # Provides an instance of Corvid's built-in plugin.
      #
      # @return [Corvid::Builtin::BuiltinPlugin] A plugin instance.
      def builtin_plugin
        @@builtin_plugin ||= (
          require 'corvid/builtin/builtin_plugin'
          ::Corvid::Builtin::BuiltinPlugin.new
        )
      end

      # Returns the names of all features installed for a given plugin.
      #
      # @param [Plugin|String] plugin A plugin instance, or name of a plugin.
      # @return [Array<String>] An array of feature names, _not_ feature ids. May return an empty array but never `nil`.
      def features_installed_for_plugin(plugin)
        plugin_name= plugin.is_a?(Plugin) ? plugin.name : plugin
        (feature_registry.read_client_features || [])
          .map   {|f|   split_feature_id f }
          .select{|p,f| plugin_name === p }
          .map   {|p,f| f }
      end

      # Reads and parses the contents of the client's {Constants::VERSIONS_FILE VERSIONS_FILE} if it exists.
      #
      # @return [nil|Hash<String,Fixnum>] The version numbers for each plugin or `nil` if the file wasn't found.
      def read_client_versions
        if File.exists?(Constants::VERSIONS_FILE)
          vers= YAML.load_file(Constants::VERSIONS_FILE)
          validate_versions! vers, "\nCheck your #{Constants::VERSIONS_FILE} file."
          vers
        else
          nil
        end
      end

      # Reads and parses the contents of the client's {Constants::VERSIONS_FILE VERSIONS_FILE}.
      #
      # @return [Hash<String,Fixnum>] The version numbers for each plugin.
      # @raise If the file doesn't exist.
      # @see read_client_version
      def read_client_versions!
        vers= read_client_versions
        raise "File not found: #{Constants::VERSIONS_FILE}\nYou must install Corvid first." if vers.nil?
        vers
      end

      # Validates an in-memory representation of a {Constants::VERSIONS_FILE VERSIONS_FILE}.
      #
      # @param [Hash<String,Fixnum>] vers A hash of plugins to the version of corresponding resources installed.
      # @param [String] errmsg_suffix Optional text to append to error messages when validation fails.
      # @raise If any problems are discovered with the content.
      # @return [void]
      def validate_versions!(vers, errmsg_suffix=nil)
        s= errmsg_suffix ? errmsg_suffix.sub(/\a(?!=\s)/,' ') : ''
        raise "Invalid version settings, hash expected. Received: #{vers.inspect}.#{s}" unless vers.is_a? Hash
        vers.each do |p,v|
          raise "Invalid plugin name: #{p.inspect}." unless p.is_a? String
          raise "Invalid version for #{p}: #{v.inspect}. Number expected." unless v.is_a? Fixnum
        end
      end

      protected

      # The resource directory that contains the appropriate version (as specified by {#with_resources}) of Corvid
      # resources.
      #
      # @return [String] An existing directory.
      # @raise If resources haven't been made available by {#with_resources}.
      def res_dir
        $corvid_global_thor_source_root || raise("Resources not available. Call with_resources() first.")
      end

      # The current resource-patch manager (as specified by {#with_resources}) that the generator will use.
      #
      # @return [ResPatchManager]
      # @raise If resources haven't been made available by {#with_resources}.
      def rpm
        return @@rpm if @@rpm
        raise("Resources not available. Call with_resources() first.")
      end

      # Makes the latest version of a plugin's resources available to generators.
      #
      # @param [Plugin] plugin The plugin providing the resources.
      # @yieldparam [Fixnum] ver The version of the resources being used.
      # @return The return result of `block`.
      # @see #with_resources
      def with_latest_resources(plugin, &block)
        with_resources plugin, :latest, &block
      end

      # Makes available to generators the version of a plugin's resources as declared in the client's
      # {Constants::VERSIONS_FILE VERSIONS_FILE}.
      #
      # @param [Plugin] plugin The plugin providing the resources.
      # @yieldparam [Fixnum] ver The version of the resources being used.
      # @return The return result of `block`.
      # @see #with_resources
      def with_installed_resources(plugin, &block)
        with_resources plugin, :installed, &block
      end

      # Works with {ResPatchManager} to provide generators with an specified version of Corvid resources.
      #
      # @note Only one version of resources can be made available at one time. Nested calls to this method requesting
      #   the same plugin and version (reentrancy) will be allowed, but a nested call for a differing version will fail.
      #
      # @overload with_resources(dir, &block)
      #   @param [String] dir The directory where the resources can be found.
      #   @yieldparam [void]
      # @overload with_resources(plugin, ver, &block)
      #   @param [Plugin] plugin The plugin providing the resources.
      #   @param [Fixnum|:installed|:latest] ver The version of resources to use.
      #   @yieldparam [Fixnum] ver The version of the resources being used.
      # @return The return result of `block`.
      # @raise If resources of a different plugin or version are already available.
      def with_resources(arg1, arg2=nil, &block)
        # Parse args
        plugin= ver= dir= nil
        if arg2
          plugin,ver = arg1,arg2
        else
          ver= dir= arg1
        end
        plugin_rpm= plugin ? rpm_for(plugin) : nil
        plugin_name= plugin ? plugin.name : 'Not provided.'

        # Check args
        raise "Block required." unless block
        case ver
        when Fixnum
        when :latest
          raise "Plugin required but not provided." unless plugin_rpm
          ver= plugin_rpm.latest_version
        when :installed
          raise "Plugin required but not provided." unless plugin_rpm
          ver= read_client_versions![plugin_name]
          raise "Version not available for plugin '#{plugin_name}', resources don't seem to have been installed yet." unless ver
        when String
          raise "Directory doesn't exist: #{ver}" unless Dir.exists?(ver)
        else
          raise "Invalid version: #{ver.inspect}"
        end

        # Make sure no conflict
        if @@with_resource_plugin and plugin_name != @@with_resource_plugin
          raise "Nested calls with different plugins not supported. This should never occur; BUG!\nInitial: #{@@with_resource_plugin.inspect}\nProposed: #{plugin_name.inspect}"
        end
        if @@with_resource_version and ver != @@with_resource_version
          raise "Nested calls with different versions not supported. This should never occur; BUG!\nInitial: #{@@with_resource_version.inspect}\nProposed: #{ver.inspect}"
        end

        @@with_resource_depth += 1
        begin

          # Run locally if resources already available (i.e. nested call)
          if @@with_resource_depth > 1
            return block.(ver)
          end

          # Logic for setting initial state
          setup_proc= lambda {|dir|
            @@with_resource_plugin= plugin_name
            @@with_resource_version= ver
            @@with_resource_features= plugin ? features_installed_for_plugin(plugin_name) : 'plugin not provided'
            @@rpm= plugin_rpm
            @source_paths= [dir]
            $corvid_global_thor_source_root= dir
          }

          # If dir already provided, use it
          if ver.is_a?(String)
            setup_proc.call ver
            return block.()
          else
            # Deploy resources via RPM
            plugin_rpm.with_resources(ver) {|dir|
              setup_proc.call dir
              return block.(ver)
            }
          end

        ensure
          # Clean up when done
          self.class.clear_with_resource_state if (@@with_resource_depth -= 1) == 0
        end
      end

      # Adds feature ids to the client's {Constants::FEATURES_FILE FEATURES_FILE}.
      #
      # Only feature ids not already in the file will be added, and {Constants::FEATURES_FILE FEATURES_FILE} will only
      # be updated if there is something to add.
      #
      # @param [Array<String>] feature_ids
      # @return [Boolean] `true` if new features were added to the client's features, else `false`.
      def add_features(*feature_ids)
        validate_feature_ids! *feature_ids

        # Read currently installed features
        installed= feature_registry.read_client_features || []
        size_before= installed.size

        # Add features
        feature_ids.flatten.each do |feature|
          installed<< feature unless installed.include?(feature)
        end

        # Write back to disk
        if installed.size != size_before
          write_client_features installed
          true
        else
          false
        end
      end
      alias :add_feature :add_features

      # Adds a plugin to the client's {Constants::PLUGINS_FILE PLUGINS_FILE}.
      #
      # Plugin attributes in the file are re-written. For example, if a plugin changes its require-path then this will
      # update the client's file to reflect as such.
      #
      # @param [Plugin] plugin The plugin instance.
      # @return [true]
      def add_plugin(plugin)
        name= plugin.name
        validate_plugin_name! name
        pdata= plugin_registry.read_client_plugin_details
        pdata ||= {}
        pdata[name]= {path: plugin.require_path, class: plugin.class.to_s}
        create_file Constants::PLUGINS_FILE, pdata.to_yaml, force: true
        true
      end

      # Adds a resource version for a plugin to a client's {Constants::VERSIONS_FILE VERSIONS_FILE}.
      #
      # If the client's file doesn't exist, it will be created. If the given plugin isn't registered in the versions
      # file then it will be added, else updated.
      #
      # @param [String|Plugin] plugin_or_name The name of a registered plugin, or the plugin instance itself.
      # @param [Fixnum] version The version of the resources being used for the plugin.
      # @return [true]
      def add_version(plugin_or_name, version)
        plugin_name= plugin_or_name.is_a?(Plugin) ? plugin_or_name.name : plugin_or_name
        vers= read_client_versions || {}
        vers[plugin_name]= version
        write_client_versions vers
        true
      end

      # Installs a plugin into an existing Corvid project.
      #
      # If already installed, then nothing happens.
      #
      # Roughly does the following:
      #
      # 1. Validates the plugin's requirements are met.
      # 1. Installs the plugin.
      # 1. Runs the plugin's `after_installed` callback.
      # 1. Installs features declared in the plugin's `auto_install_features`.
      #
      # @param [String|Plugin] plugin_or_name The name of a registered plugin, or the plugin instance itself.
      # @return [Boolean] `true` if installed, `false` if already installed.
      # @raise If plugin's requirements aren't satisfied.
      def install_plugin(plugin_or_name)
        plugin= plugin_or_name.is_a?(Plugin) ? plugin_or_name : plugin_registry.instance_for(plugin_or_name)

        # Check if plugin installed yet
        installed= plugin_registry.read_client_plugins || []
        return false if installed.include? plugin.name

        # Validate plugin requirements
        rv= new_requirement_validator
        rv.add plugin.requirements
        rv.validate!

        # Install plugin
        add_plugin plugin

        # Run post-install hook
        plugin.run_callback :after_installed, context: self

        # Auto-install features
        features= plugin.auto_install_features || []
        features.each {|feature_name|
          install_feature plugin, feature_name
        }

        true
      end

      # Installs a feature into an existing Corvid project.
      #
      # If the feature is already installed then this tells the user thus and stops.
      #
      # @param [String|Plugin] plugin_or_name The instance or name of the plugin that the feature belongs to.
      # @param [String] feature_name The feature name to install.
      # @option options [Boolean] :run_bundle_at_exit (false) If enabled, then {#run_bundle_at_exit} will be called
      #   after the feature is added.
      # @option options [Boolean] :say_if_installed (true) If enabled and feature is already installed, then display a
      #   message indicating so to the user.
      # @return [Boolean] `true` if installed, `false` if already installed.
      #
      # @raise If the feature's encompassing plugin isn't already installed.
      # @raise If failed to read client's installed features and resource versions.
      # @raise If the feature isn't available at the current version of resources (i.e. update required).
      # @raise If feature's requirements aren't satisfied.
      def install_feature(plugin_or_name, feature_name, options={})
        options= DEFAULT_OPTIONS_FOR_INSTALL_FEATURE.merge options
        options.validate_option_keys DEFAULT_OPTIONS_FOR_INSTALL_FEATURE.keys
        plugin= plugin_or_name.is_a?(Plugin) ? plugin_or_name : plugin_registry.instance_for(plugin_or_name)
        feature_id= feature_id_for(plugin.name, feature_name)

        # Read client details
        vers= read_client_versions || {}
        feature_ids= feature_registry.read_client_features || []

        # Check if feature already installed
        if feature_ids.include? feature_id
          say "Feature '#{feature_id}' already installed." if options[:say_if_installed]
          return false
        end

        # Ensure plugin installed
        client_plugins= plugin_registry.read_client_plugins || []
        unless client_plugins.include? plugin.name
          raise "Can't install feature '#{feature_id}' because '#{plugin.name}' plugin is not installed."
        end

        # Ensure resources up-to-date
        ver= vers[plugin.name]
        f= feature_registry.instance_for(feature_id)
        if ver and f and f.since_ver > ver
          raise "The #{feature_id} feature requires at least v#{f.since_ver} of #{plugin.name} resources, but you are currently on v#{ver}.\nPlease perform an update first and then try again."
        end

        # Install feature
        # TODO remember that plugins can call install_feature 'corvid:test_unit' & install feature of a diff plugin
        @feature_being_installed= feature_name
        with_resources(plugin, ver || :latest) {|actual_ver|
          fi= feature_installer!(feature_name)

          # Validate feature requirements
          rv= new_requirement_validator
          rv.add f.requirements
          rv.add fi.requirements if fi.respond_to?(:requirements)
          rv.validate!

          # Install
          with_action_context fi, &:install
          add_feature feature_id
          add_version plugin, actual_ver unless ver == actual_ver
          yield actual_ver if block_given?
          run_bundle_at_exit() if options[:run_bundle_at_exit]
        }
      ensure
        @feature_being_installed= nil
      end

      # @!visibility private
      DEFAULT_OPTIONS_FOR_INSTALL_FEATURE= {
        run_bundle_at_exit: false,
        say_if_installed: true,
      }.freeze

      # Returns the filename of a feature installer.
      # @return [String] An unverified full path.
      def feature_installer_file(dir = res_dir(), feature_name)
        validate_feature_name! feature_name
        "#{dir}/corvid-features/#{feature_name}.rb"
      end
      # Returns the filename of an existing feature installer.
      # @return [String] A verified full path.
      # @raise If the feature installer doesn't exist.
      def feature_installer_file!(dir = res_dir(), feature_name)
        filename= feature_installer_file(dir, feature_name)
        unless File.exists?(filename)
          raise "File not found: #{filename}\n"\
            "Feature installer for '#{feature_name}' doesn't seem to exist. Check the plugin's resources and try again."
        end
        filename
      end

      # Returns the code of a feature installer, if available.
      # @return [nil|String] The installer file contents or `nil` if the file doesn't exist.
      def feature_installer_code(dir = res_dir(), feature_name)
        file= feature_installer_file(dir, feature_name)
        return nil unless File.exist?(file)
        code= File.read(file)
        allow_declarative_feature_installer_config(code, feature_name)
      end
      # Returns the code of an existing feature installer.
      # @return [String] The feature installer contents.
      # @raise If the feature installer doesn't exist.
      def feature_installer_code!(dir = res_dir(), feature_name)
        code= feature_installer_code(dir, feature_name)
        code or (
          feature_installer_file!(dir, feature_name) # This will raise its own error if file not found
          raise "Unable to read feature installer code for '#{feature_name}'."
        )
      end

      # Wraps the code of a feature installer so that values/code blocks are provided as arguments to pre-defined
      # keywords.
      #
      # Eg. the following code:
      #     since_ver 2
      #
      #     install {
      #       do_stuff
      #     }
      #
      # will be translated into:
      #
      #     def since_ver
      #       2
      #     end
      #
      #     def install
      #       do_stuff
      #     end
      #
      # Why? So that things like this fail fast, rather than ambiguous errors occuring later.
      #     instal {  # <-- typo, this causes an error on parsing now
      #       do_stuff
      #     }
      #
      # @param [String] code The feature installer code.
      # @param [String] feature The name of the feature that the code belongs to (for generating clear error-messages).
      # @return [String] The feature installer code wrapped in magic goodness!
      def allow_declarative_feature_installer_config(code, feature)
        iv= '@__corvid_fi_'
        new_code= []
        new_code.concat FEATURE_INSTALLER_VALUES_DEFS.map{|m| "def #{m}(v); #{iv}#{m}= v; end"}
        new_code.concat FEATURE_INSTALLER_CODE_DEFS.map{|m| %|
                          def #{m}(&b)
                            raise "Block not provided for #{m} in #{feature} feature-installer." if b.nil?
                            #{iv}#{m}= b
                          end
                        |}
        new_code<< code
        new_code.concat FEATURE_INSTALLER_VALUES_DEFS.map{|m| %|
                          if instance_variable_defined? :#{iv}#{m}
                            def #{m}; #{iv}#{m} end
                          else
                            undef :#{m}
                          end
                        |}
        new_code.concat FEATURE_INSTALLER_CODE_DEFS.map{|m| %|
                          if instance_variable_defined? :#{iv}#{m}
                            def #{m}(*args) #{iv}#{m}.call(*args) end
                          else
                            undef :#{m}
                          end
                        |}
        code= new_code.join "\n"
        code
      end

      # Creates an instance of a feature installer, if the installer is available.
      # @return [nil|GollyUtils::Delegator<Base>] An instance of the feature installer, or `nil` if the installer
      #   doesn't exist.
      # @raise If the feature installer code fails to parse.
      def feature_installer(dir = res_dir(), feature_name)
        code= feature_installer_code(dir, feature_name)
        code && dynamic_installer(code, feature_name)
      end
      # Creates an instance of an existing feature installer.
      # @return [GollyUtils::Delegator<Base>] An instance of the feature installer.
      # @raise If the installer file doesn't exist.
      # @raise If the feature installer code fails to parse.
      def feature_installer!(dir = res_dir(), feature_name)
        installer= feature_installer(dir, feature_name)
        installer or (
          feature_installer_file!(dir, feature_name) # This will raise its own error if file not found
          raise "Unable to create feature installer for '#{feature_name}'."
        )
      end

      # Turns given code into an object that delegates all undefined methods to this generator.
      #
      # @param [String] code The Ruby code to evaluate.
      # @param [String] feature The name of the feature that the code belongs to (for generating clear error-messages).
      # @param [nil|Fixnum] ver The version of the resources that the code belongs to (for generating clear
      #   error-messages).
      # @return [GollyUtils::Delegator<Base>] A delegator with the provided code on top.
      def dynamic_installer(code, feature, ver=nil)
        d= GollyUtils::Delegator.new self, allow_protected: true
        add_dynamic_code! d, code, feature, ver
      end

      # Mixes given code into an existing object, and wraps each new public method with decorated error-messages when
      # things go wrong.
      #
      # @param [Object] obj The object to embelish with given code.
      # @param [String] code The Ruby code to evaluate.
      # @param [String] feature The name of the feature that the code belongs to (for generating clear error-messages).
      # @param [nil|Fixnum] ver The version of the resources that the code belongs to (for generating clear
      #   error-messages).
      # @return [Object] Returns the `obj` argument.
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

      # Creates a requirement validator, preconfigured with data about the state of the client's Corvid project.
      #
      # @return [Corvid::RequirementValidator] A new requirement validator instance.
      def new_requirement_validator
        rv= ::Corvid::RequirementValidator.new
        rv.set_client_state(
          plugin_registry.read_client_plugins,
          feature_registry.read_client_features,
          read_client_versions
        )
        rv
      end

      # Validates all given requirements.
      #
      # @param requirements Requirements to pass to {Corvid::RequirementValidator#add}. See that method for details.
      # @return [true]
      # @raise If any requirements fail validation.
      def validate_requirements!(*requirements)
        rv= new_requirement_validator
        rv.add *requirements
        rv.validate!
        true
      end

      # Creates or replaces the client's {Constants::VERSIONS_FILE VERSIONS_FILE}.
      #
      # @param [Hash<String,Fixnum>] vers A hash of plugin names to the version of corresponding resources installed.
      # @return [self]
      def write_client_versions(vers)
        # TODO doesn't call rpm.validate_version! >>> rpm[plugin].validate_version! ver, 1
        validate_versions! vers
        create_file Constants::VERSIONS_FILE, vers.to_yaml, force: true
        self
      end

      # Creates or replaces the client's {Constants::FEATURES_FILE FEATURES_FILE}.
      #
      # @param [Array<String>] feature_ids The ids of all features installed.
      # @return [self]
      def write_client_features(feature_ids)
        raise "Invalid features. Array expected. Got: #{feature_ids.inspect}" unless feature_ids.is_a?(Array)
        validate_feature_ids! *feature_ids
        create_file Constants::FEATURES_FILE, feature_ids.to_yaml, force: true
        self
      end

      # Generates and records a bunch of state needed to register files for auto-update.
      #
      # @example
      #     with_auto_update_details(require: __FILE__) {
      #       template2_au 'lib/%project_name%/some_template.rb.tt'
      #     }
      #
      # @yield Invokes the given block with the auto-update state in place.
      # @param [Hash] options
      # @option options [String] :plugin_name The name of the plugin providing the updatable resource.
      #   Determined automatically if not provided provided {#with_resources} has been called.
      # @option options [Plugin] :plugin An alternative to specifying `:plugin`.
      # @option options [Base|Class<Base>] :generator (self) The generator (or class) that is generating the file.
      #   Determined automatically if not provided.
      # @option options [nil|String] :require (nil) An optional path to `require` to load the generator class. Absolute
      #   paths will be converted so it is recommended you pass in `__FILE__`.
      # @option options [Array<String>] :cli_args CLI arguements the generator requires for instanciation.
      #   Determined automatically if not provided.
      # @option options [Array<String>] :cli_opts CLI arguments that configure Thor options. Required for instanciation.
      #   Determined automatically if not provided.
      # @return [void]
      def with_auto_update_details(options = {})

        # Option: plugin_name / plugin
        plugin_name= options[:plugin_name] || options[:plugin] || @@with_resource_plugin
        plugin_name= plugin_name.name if plugin_name.is_a?(Plugin)
        raise "Plugin name not provided." unless plugin_name

        # Option: generator
        generator_class= options[:generator] || self
        generator_class= generator_class.class unless generator_class.is_a? Class
        raise "Invalid generator class: #{generator_class.inspect}" unless generator_class.superclasses.include? Base

        # Option: require
        if generator_require_path= options[:require]
          # Convert full paths
          if /^\/|\.rb$/ === generator_require_path
            generator_require_path= File.expand_path generator_require_path
            candidates= $:.map{|p|
              generator_require_path.sub /#{Regexp.quote File.expand_path p}[\\\/]+/, ''
            }
            c= candidates.sort_by(&:size).first
            if c == generator_require_path
              raise "Unable to turn full path into a $LOAD_PATH-relative require-path: #{generator_require_path}"
            end
            generator_require_path= c.sub /\.rb$/, ''
          end
        end

        # Option: cli_args & cli_opts
        generator_cli_args= options[:cli_args] || @_initializer[0]
        generator_cli_opts= options[:cli_opts] || @_initializer[1]

        # Create auto-update details
        aug= {class: generator_class.to_s}
        aug[:require]= generator_require_path if generator_require_path
        aug[:args]= generator_cli_args if generator_cli_args && !generator_cli_args.empty?
        aug[:opts]= generator_cli_opts if generator_cli_opts && !generator_cli_opts.empty?
        au= {plugin: plugin_name, generator: aug}

        # Confirm data allows successful re-creation of generator
        create_generator_from_au_data au

        # Yield with details in place
        old= @with_auto_update_details
        @with_auto_update_details= au
        begin
          yield
        ensure
          @with_auto_update_details= old
        end
      end

      # A special version of {ActionExtensions#template2} that registers the target file for auto-updates.
      #
      # @overload template2_au(file, *template_var_keys, options={})
      #   @param [String] file The template source file.
      #   @param [Array<Symbol>] template_var_keys A list of method names that provide template values, that should
      #     have their current values saved and reused in future updates.
      #   @param [Hash] options Options for {ActionExtensions#template2}.
      #   @return [String] The name of the file generated by the template.
      #   @raise [RuntimeError] If {#with_auto_update_details} hasn't been called first.
      def template2_au(file, *args)
        raise "Call with_auto_update_details() first." unless @with_auto_update_details

        arg_keys= args.dup
        options= arg_keys.last.is_a?(Hash) ? arg_keys.pop : {}
        au= @with_auto_update_details
        unless arg_keys.empty?
          au= au.merge args: Hash[arg_keys.map{|k| [k,action_context.send(k)] }]
        end
        au= au.merge options: options

        template2 file, options.merge(auto_update: au)
      end

      # Creates a new instance of a generator whose details have been saved in {Constants::AUTO_UPDATE_FILE}.
      #
      # @param [Hash<Symbol,Object>] au_data Auto-update data.
      # @return [nil|Base] A new instance of the generator or `nil` if the data doesn't specify generator details.
      def create_generator_from_au_data(au_data)
        if gd= au_data[:generator]
          require gd[:require] if gd[:require]
          raise "Class name not provided for generator.\n#{au_data.inspect}" unless gd[:class]
          klass= eval gd[:class]
          cli_args= gd[:args] || []
          cli_opts= gd[:opts] || []
          generator= klass.new(cli_args, cli_opts)
        else
          nil
        end
      end

      # When a new {ResPatchManager} is created this method is called to provide any custom configuration.
      #
      # @param [ResPatchManager] rpm The object to configure.
      # @return [void]
      def configure_new_rpm(rpm)
      end

      # Creates two temporary directories to generally be used as 'from' and 'to' locations when generating patches,
      # and configures the generator to use whatever the current directory is as its target/deployment location.
      #
      # @param [String] project_dir_name The client's project directory basename.
      # @yieldparam [String] from_dir Temporary directory #1.
      # @yieldparam [String] to_dir Temporary directory #2.
      # @return [void]
      def with_temp_from_to_dirs(project_dir_name)
        @destination_stack.push '.'
        pop_dest_stack= true
        Dir.mktmpdir {|tmpdir|
          Dir.mkdir from_dir= "#{tmpdir}/a"
          Dir.mkdir from_dir= "#{from_dir}/#{project_dir_name}"
          Dir.mkdir to_dir= "#{tmpdir}/b"
          Dir.mkdir to_dir= "#{to_dir}/#{project_dir_name}"
          yield from_dir, to_dir
        }
      ensure
        @destination_stack.pop if pop_dest_stack
      end

      # Wrapper for code that will apply a patch.
      #
      # * Allows interactive patching for the duration of the block.
      # * Puts suitable messages on the screen before and after patching.
      #
      # @param [ResPatchManager] rpm The RPM that will be used to apply patches.
      # @param [String] msg A description of what is about to happen, to be displayed to the user.
      # @yield The patching should occur within this block.
      # @yieldreturn [Boolean] Whether merge conflicts occurred.
      # @return [void]
      def patch(rpm, msg, &block)
        rpm.allow_interactive_patching do
          say_status 'patch', msg, :cyan

          conflicts= block.()

          if conflicts
            say_status 'patch', 'Applied but with merge conflicts.', :red
          else
            say_status 'patch', 'Applied cleanly.', :green
          end
        end
      end

      # Is a feature installed (or in the process of being installed)?
      #
      # For use in templates and in conjunction with {#regenerate_template_with_feature}.
      #
      # @param [Symbol|String] feature_name The feature name (not feature id).
      # @return [Boolean]
      # @raise If resources haven't been made available by {#with_resources} or {#override_installed_features}.
      def feature_installed?(feature_name)
        :feature_name.validate_lvar_type!{[ Symbol, String ]}
        __features_installed.include? feature_name.to_s
      end

      # Are a number of features installed (or in the process of being installed)?
      #
      # For use in templates and in conjunction with {#regenerate_template_with_feature}.
      #
      # @param [Array<Symbol|String>] feature_names Feature names (not feature ids).
      # @return [Boolean] If all feature names are installed (or in the process of being installed).
      # @raise If resources haven't been made available by {#with_resources} or {#override_installed_features}.
      def features_installed?(*features)
        features.flatten.compact.all?{|f| feature_installed? f }
      end

      # Regenerates a template previously generated by another feature in the same plugin via
      # {ActionExtensions#template2}. The template is expected to produce different content by checking
      # {#feature_installed?}.
      #
      # This action is only valid in feature installers and will not work outside of {#install_feature}.
      #
      # @example Feature installers
      #     # Feature installer for a feature called "hot".
      #     install {
      #       template2 'example.txt.tt'
      #     }
      #
      #     # Feature installer for a feature called "cold".
      #     requirements 'example:hot'
      #     install {
      #       regenerate_template_with_feature 'example.txt.tt'
      #     }
      #
      # @example Template: `example.txt.tt`
      #     This is an example template.
      #
      #     <% if feature_installed? :hot -%>
      #       It's a hot day.
      #     <% end -%>
      #
      #     <% if feature_installed? :cold -%>
      #       It's getting cold.
      #     <% end -%>
      #
      # @param [String] template_name The template name to pass to {ActionExtensions#template2}.
      # @param [Hash] options Options to pass to {ActionExtensions#template2}.
      # @return [void]
      def regenerate_template_with_feature(template_name, options={})
        # TODO Noisy. Prints 2 lines about tmp files being written. Probaby happening during template updating too.
        project_dir_name= File.basename(Dir.pwd)
        preload_template_vars

        with_temp_from_to_dirs(project_dir_name) {|from_dir, to_dir|
          files= []
          gen_proc= ->(d){ files<< template2(template_name, options) }

          # Generate without feature
          feature_being_installed= @feature_being_installed
          begin
            @feature_being_installed= nil
            Dir.chdir from_dir, &gen_proc
          ensure
            @feature_being_installed= feature_being_installed
          end

          # Generate with feature
          Dir.chdir to_dir, &gen_proc

          # Apply patch
          patch rpm, files.first do
            rpm.migrate_changes_between_dirs from_dir, to_dir, '.', files
          end
        }
      end

      # For the duration of the given block, {#feature_installed?} will reference the features specified here, rather
      # than the features that were actually installed when {#with_resources} was called.
      #
      # @overload override_installed_features(plugin)
      #   @param [Plugin|String] plugin A plugin (or its name), in which case the feature set will be determined by
      #     calling {#features_installed_for_plugin}.
      # @overload override_installed_features(feature_names)
      #   @param [Array<String>] feature_names The list of installed features to use.
      # @yield Invokes the given block with the given features in place.
      # @return [Object] Whatever the given block returns.
      def override_installed_features(arg)
        :arg.validate_lvar_type!{[ Array, String, Plugin ]}
        arg= arg.name if arg.is_a? Plugin
        arg= features_installed_for_plugin(arg) if arg.is_a? String
        features= arg.flatten.compact.map{|f| f.to_s}

        old= @overridden_installed_features
        begin
          @overridden_installed_features= features
          return yield
        ensure
          @overridden_installed_features= old
        end
      end

      private

      def __features_installed
        features= @overridden_installed_features || @@with_resource_features
        raise "Features not available. Call with_resources() or override_installed_features() first." unless features
        raise "Features not available: #{features}." if features.is_a? String
        features= features + [@feature_being_installed] if @feature_being_installed
        features
      end

      # Creates a new {ResPatchManager} for a given plugin.
      #
      # @param [Plugin] The plugin for which to create an RPM.
      # @return [ResPatchManager] A new RPM.
      def new_rpm_for(plugin)
        ::Corvid::ResPatchManager.new(plugin.resources_path)
          .tap{|rpm| configure_new_rpm rpm }
      end

      # @!visibility private
      def self.clear_with_resource_state
        @@with_resource_depth= 0
        @@with_resource_plugin= nil
        @@with_resource_version= nil
        @@with_resource_features= nil
        @@rpm= nil
        @source_paths= nil
        $corvid_global_thor_source_root= nil
      end
      clear_with_resource_state

      # Re-enable Thor's support for assuming all public methods are tasks
      no_tasks {}
    end
  end
end
