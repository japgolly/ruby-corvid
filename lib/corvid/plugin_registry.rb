require 'golly-utils/singleton'
require 'corvid/constants'
require 'corvid/plugin'

module Corvid
  class PluginRegistry
    include GollyUtils::Singleton

    PLUGIN_NAME_FMT= '[^ :]+'.freeze
    PLUGIN_NAME_REGEX= /^#{PLUGIN_NAME_FMT}$/

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
      load_client_plugins unless @instance_cache

      unless @instance_cache.has_key?(name)
        raise "Unknown plugin: #{name}. Is it specified in #{Constants::PLUGINS_FILE}?\nKnown plugins are: #{@instance_cache.keys.sort.inspect}"
      end

      @instance_cache[name]
    end

    # TODO
    #
    # @param [Boolean] force If enabled, then the cached value will be discarded.
    # @return [Hash<String,nil|Plugin>] An instance of each client-installed feature. May return an empty array but never `nil`.
    def instances_for_installed#(force=false)
      load_client_plugins unless @instance_cache
      @instance_cache
    end

    def validate_plugin_name!(plugin_name)
      unless plugin_name.is_a? String
        raise "Invalid plugin name: #{plugin_name.inspect}. String expected."
      end
      unless PLUGIN_NAME_REGEX === plugin_name
        raise "Invalid plugin name: '#{plugin_name}'. Must match regex: #{PLUGIN_NAME_REGEX}"
      end
      true
    end

    protected

    def load_client_plugins
      @instance_cache= {}

      # Add client plugins
      if plugin_manifest= read_client_plugin_details
        plugin_manifest.each {|name,data|

          # Create a new instance
          path,class_name = data[:path],data[:class]
          require path if path
          klass= eval(class_name.sub /^(?!::)/,'::')
          @instance_cache[name]= klass.new
        }
      end

      @instance_cache.freeze
    end

  end
end
