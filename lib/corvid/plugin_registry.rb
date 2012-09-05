require 'golly-utils/singleton'
require 'corvid/constants'
require 'corvid/plugin'
require 'corvid/naming_policy'

module Corvid
  class PluginRegistry
    include GollyUtils::Singleton
    include Corvid::NamingPolicy

    def initialize
      clear_cache
    end

    # Abandons all cached plugin instances and clears the registry.
    #
    # Calls to {#instance_for} will return new plugins.
    #
    # @return [self]
    def clear_cache
      @instance_cache= nil
      self
    end

    # Reads the client's {Constants::PLUGINS_FILE PLUGINS_FILE} file if it exists, and returns a list of installed
    # plugin names.
    #
    # @return [nil,Array<String>] An array of installed plugins, or `nil` if the file wasn't found.
    def read_client_plugins
      pd= read_client_plugin_details
      pd && pd.keys
    end

    # Reads and parses the contents of the client's {Constants::PLUGINS_FILE PLUGINS_FILE} if it exists.
    #
    # @return [nil,Hash<String,Hash<Symbol,Object>>] A map of plugins to their propreties, or `nil` if the file wasn't
    #   found.
    def read_client_plugin_details
      if File.exists? Constants::PLUGINS_FILE
        p= YAML.load_file Constants::PLUGINS_FILE
        raise "Invalid #{Constants::PLUGINS_FILE}. Hash expected but got #{p.class}." unless p.is_a?(Hash)
        p
      else
        nil
      end
    end

    # Provides an instance of a registered plugin. If the registry is empty then client-installed plugins will be loaded
    # automatically.
    #
    # Subsequent calls for the same plugin name will return the same plugin instance.
    #
    # @note If the client's installed plugin list changes, call {#clear_cache} first.
    # @note To manually provide plugins rather than depending on the client's installation, use {#register}.
    #
    # @param [String] name The plugin name.
    # @return [Plugin] A plugin instance.
    # @raise If the requested plugin isn't installed registered.
    def instance_for(name)
      validate_plugin_name! name
      register_client_plugins unless @instance_cache

      unless @instance_cache.has_key?(name)
        raise "Unknown plugin: #{name}. Is it specified in #{Constants::PLUGINS_FILE}?\nKnown plugins are: #{@instance_cache.keys.sort.inspect}"
      end

      @instance_cache[name]
    end
    alias :[] :instance_for

    # Provides an instance of each client-installed plugin.
    #
    # @note If plugins have been manually registered via {#register} then this will simply return everything in the
    #   registry.
    #
    # @return [Hash<String,Plugin>] A map of plugin names to plugin instances, for each client-installed plugin.
    #   May return an empty array but never `nil`.
    def instances_for_installed
      register_client_plugins unless @instance_cache
      @instance_cache.dup
    end

    # Installs a manually instanciated plugin into the registry.
    #
    # @param [Plugin] plugin A plugin instance.
    # @return [self]
    def register(plugin)
      @instance_cache ||= {}
      @instance_cache[plugin.name]= plugin
      self
    end

    # Reads the client's {Constants::PLUGINS_FILE PLUGINS_FILE}, then loads and caches an instance of every plugin
    # declared.
    #
    # Plugins are added to the registry but nothing will be removed. In the case that this is undesired, simply call
    # {#clear_cache} first.
    #
    # @return [self]
    def register_client_plugins
      @instance_cache ||= {}

      # Add client plugins
      if plugin_manifest= read_client_plugin_details
        plugin_manifest.each {|name,data|
          validate_plugin_name! name

          # Create a new instance
          path,class_name = data[:path],data[:class]
          require path if path
          klass= eval(class_name.sub /^(?!::)/,'::')
          plugin= klass.new

          raise "Plugin name mismatch. #{name.inspect} does not match #{plugin.name.inspect}." unless name == plugin.name
          @instance_cache[name]= plugin
        }
      end

      self
    end

  end
end
