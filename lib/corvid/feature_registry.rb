require 'golly-utils/singleton'
require 'corvid/constants'
require 'corvid/plugin_registry'
require 'corvid/naming_policy'

module Corvid
  # Provides information and instances of plugin {Feature}s.
  # Specifically:
  #
  # * Maintains a registry of known/installed features.
  # * Maintains a cache of {Feature} instances.
  # * Provides functions to inspect the feature configuration of a Corvid project.
  class FeatureRegistry
    include GollyUtils::Singleton
    include Corvid::NamingPolicy

    # @!attribute [rw] plugin_registry
    #   @return [PluginRegistry]
    PluginRegistry.def_accessor(self)

    def initialize
      clear_cache
    end

    # Abandons all cached feature instances and clears the registry.
    #
    # @return [self]
    def clear_cache
      @feature_manifest= nil
      @instance_cache= {}
      @instances_for_installed= nil
      self
    end

    # Reads and parses the contents of the client's {Constants::FEATURES_FILE FEATURES_FILE} if it exists.
    #
    # @return [nil|Array<String>] A list of feature ids or `nil` if the file wasn't found.
    def read_client_features
      if File.exists? Constants::FEATURES_FILE
        v= YAML.load_file Constants::FEATURES_FILE
        raise "Invalid #{Constants::FEATURES_FILE}. Array expected but got #{v.class}." unless v.is_a?(Array)
        raise "Invalid #{Constants::FEATURES_FILE}. At least 1 feature expected but not defined." if v.empty? #TODO del this
        v
      else
        nil
      end
    end

    # Reads and parses the contents of the client's {Constants::FEATURES_FILE FEATURES_FILE}.
    #
    # @return [Array<String>] A list of feature ids.
    # @raise If file not found.
    # @see #read_client_features
    def read_client_features!
      features= read_client_features
      raise "File not found: #{Constants::FEATURES_FILE}\nYou must install Corvid first. Try corvid init." if features.nil?
      features
    end

    # Returns the registry's feature manifest.
    #
    # If the registry has no feature manifest yet, then one is created by combining all feature manifests provided by
    # all plugins in the {PluginRegistry}.
    #
    # @return [Hash<String,Array<String>>] A hash with keys being feature ids, and the values being the same as the
    #   values of {Plugin#feature_manifest}.
    def feature_manifest
      if @feature_manifest.nil?

        # Registers features in installed plugins
        plugins= plugin_registry.instances_for_installed().values
        plugins.each do |p|
          register_features_in p
        end

      end
      @feature_manifest.dup
    end

    # Provides an instance of a registered feature. If the registry is empty then client-installed features will be
    # loaded automatically.
    #
    # Subsequent calls for the same feature will return the same feature instance.
    #
    # @note To manually provide features rather than depending on the client's installation, use {#register} et al.
    #
    # @param [String] feature_id The feature ID. Example: `corvid:test_spec`.
    # @return [nil|Feature] An instance of {Feature}, or `nil` if the plugin declares there is no {Feature} class for
    #   the specified feature.
    # @raise If the requested feature isn't installed registered.
    def instance_for(feature_id)
      validate_feature_id! feature_id
      feature_manifest # auto-load if registry empty

      return @instance_cache[feature_id] if @instance_cache.has_key?(feature_id)

      raise "Unknown feature: #{feature_id}. It isn't specified in any manifests." unless feature_manifest.has_key?(feature_id)

      data= feature_manifest[feature_id]
      instance= if data
          # Create a new instance
          path,class_feature_id = data
          require path if path
          klass= eval(class_feature_id.sub /^(?!::)/,'::')
          klass.new
        else
          nil
        end

      @instance_cache[feature_id]= instance
    end
    alias :[] :instance_for

    # Provides an instance of each client-installed feature.
    #
    # @note If the client's installed feature list changes, call {#clear_cache} first.
    #
    # @return [Hash<String,nil|Feature>] A map of feature ids to feature instances, for each client-installed feature.
    #   May return an empty hash but never `nil`.
    def instances_for_installed
      @instances_for_installed ||= (read_client_features || []).inject({}) {|h,f| h[f]= instance_for f; h }
    end

    # Registers a feature.
    #
    # @param [String] plugin_name The name of the plugin that the feature belongs to.
    # @param [String] feature_name The feature name.
    # @param [nil, Array<String>] data An array of the require-path, and class name of the feature.
    #   This value matches values in {Plugin#feature_manifest}.
    # @return [self]
    def register(plugin_name, feature_name, data)
      @feature_manifest ||= {}

      # Check names
      validate_plugin_name! plugin_name
      validate_feature_name! feature_name
      name= feature_id_for(plugin_name, feature_name)
      STDERR.puts "WARNING: Feature '#{name}' already registered." if @feature_manifest.has_key?(name)

      # Check data
      unless data.nil? or data.is_a?(Array) && [NilClass,String].include?(data[0].class) && data[1].is_a?(String)
        raise "Invalid feature manifest value for #{name}.\nArray of [require_path, class_name] expected, got: #{data.inspect}"
      end

      # Register
      @feature_manifest[name]= data

      self
    end

    # Registers all features in a feature manifest.
    #
    # @param [String] plugin_name The plugin name.
    # @param [Hash<String, Array<String>>] feature_manifest Feature manifest for a single plugin.
    #   See {Plugin#feature_manifest} for key and value explanations.
    # @return [self]
    def register_manifest(plugin_name, feature_manifest)
      feature_manifest.each do |name, data|
        register plugin_name, name, data
      end
      self
    end

    # Registers all features declared in a plugin.
    #
    # @param [Plugin] plugin A plugin instance with a valid name and feature manifest.
    # @return [self]
    # @see Plugin#feature_manifest
    def register_features_in(plugin)
      register_manifest plugin.name, plugin.feature_manifest
      self
    end

  end
end
