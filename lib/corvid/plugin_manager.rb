require 'corvid/environment' unless defined?(CORVID_ROOT)
require 'corvid/constants'
require 'corvid/plugin'
require 'singleton'
require 'thread'

module Corvid
  class PluginManager
    include Singleton

    # Plugin instances. Loaded on demand.
    # @return [Array<Plugin>]
    def plugins
      @plugins ||= load_plugins
    end
    attr_writer :plugins

    # Runs a given block once for each plugin available.
    #
    # @yieldparam [Plugin] plugin A plugin instance.
    # @return [self]
    def each_plugin(&block)
      plugins.each {|p| block.call p }
      self
    end

    protected

    # Loads and creates an instance of each plugin referenced in {#read_client_plugins}.
    #
    # @return [Array<Plugin>] New instances of each plugin.
    def load_plugins
      plugins= []
      @@load_plugins_mutex.synchronize do
        (read_client_plugins || []).each do |name|

          # Load plugin
          @@plugin_classes[name] ||= (
            before= Plugin.subclasses
            require "corvid/plugins/#{name}"
            new_plugin_classes= Plugin.subclasses - before
            STDERR.puts "WARNING: Plugin '#{name}' failed to provide any plugins." if new_plugin_classes.empty?
            new_plugin_classes
          )

          # Instantiate each plugin
          @@plugin_classes[name].each do |pc|
            plugins<< pc.new
          end
        end
      end
      plugins
    end

    # Reads and parses the contents of the client's {Constants::PLUGINS_FILE PLUGINS_FILE} if it exists.
    #
    # @return [nil,Array<String>] A list of plugins or `nil` if the file wasn't found.
    def read_client_plugins
      if File.exists? Constants::PLUGINS_FILE
        p= YAML.load_file Constants::PLUGINS_FILE
        raise "Invalid #{Constants::PLUGINS_FILE}. Array expected but got #{v.class}." unless p.is_a?(Array)
        p
      else
        nil
      end
    end

    private
    @@load_plugins_mutex= Mutex.new
    @@plugin_classes= {}

    #-------------------------------------------------------------------------------------------------------------------

    # Create class-method helpers that call instance-methods on the singleton instance.
    # TODO Move to GU
    public
    (self.instance.public_methods - self.class.methods)
      .reject{|m| /^_/ === m.to_s}
      .each do |m|
        class_eval "def self.#{m}(*a,&b); self.instance.send :#{m},*a,&b; end"
      end

  end
end
