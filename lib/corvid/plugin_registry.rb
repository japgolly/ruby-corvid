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

    def clear_cache
      @instance_cache= nil
      self
    end

    # @return [nil,Hash<String,Hash<Symbol,Object>>] A map of plugins to their propreties, or `nil` if the file wasn't
    #   found.
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
        raise "Invalid #{Constants::PLUGINS_FILE}. Hash expected but got #{v.class}." unless p.is_a?(Hash)
        p
      else
        nil
      end
    end

    # @param [String] name
    # @return [nil,Plugin]
    def instance_for(name)
      validate_plugin_name! name
      load_client_plugins unless @instance_cache

      unless @instance_cache.has_key?(name)
        raise "Unknown plugin: #{name}. Is it specified in #{Constants::PLUGINS_FILE}?\nKnown plugins are: #{@instance_cache.keys.sort.inspect}"
      end

      @instance_cache[name]
    end

    # TODO
    #
    # @return [Hash<String,nil|Plugin>] An instance of each client-installed feature. May return an empty array but never `nil`.
    def instances_for_installed
      load_client_plugins unless @instance_cache
      @instance_cache
    end

    protected

    def load_client_plugins
      @instance_cache= {}

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

      @instance_cache.freeze
    end

  end
end
