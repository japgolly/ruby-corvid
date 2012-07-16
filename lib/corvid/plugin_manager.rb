require 'corvid/environment' unless defined?(CORVID_ROOT)
require 'corvid/plugin'
require 'singleton'

module Corvid
  class PluginManager
    include Singleton

    attr_writer :plugin_list
    def plugin_list
      @plugin_list ||= read_plugin_list_from_file("#{APP_ROOT}/.corvid/plugins.yml") if defined?(APP_ROOT)
      @plugin_list ||= read_plugin_list_from_file('.corvid/plugins.yml')
    end

    attr_writer :plugins
    def plugins
      @plugins || load_plugins!
    end

    def load_plugins!
      plugins= []
      (plugin_list || []).each do |name|

        # Load plugin
        before= Plugin.subclasses
        require "corvid/plugins/#{name}"
        new_plugin_classes= Plugin.subclasses - before
        STDERR.puts "WARNING: Plugin '#{name}' failed to provide any plugins." if new_plugin_classes.empty?

        # Instantiate each plugin
        new_plugin_classes.each do |pc|
          plugins<< pc.new
        end
      end
      @plugins= plugins
    end

    def each_plugin(&block)
      plugins.each {|p| block.call p }
      self
    end

    protected

    def read_plugin_list_from_file(file)
      return nil unless File.exists?(file)
      r= YAML.load_file(file)
      raise "#{file} is invalid. Plugin list should be an array." unless r.is_a?(Array)
      r
    end

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
