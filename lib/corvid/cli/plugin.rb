require 'corvid/plugin'
require 'corvid/generator/plugin_cli'

module Corvid
  module CLI
    module Plugin
      extend self

      # Starts the plugin CLI handler.
      #
      # @param [Hash<Symbol,String>] options
      # @option options [Plugin] :plugin The plugin to start the CLI for.
      # @option options [String] :project_root The full path of the plugin project's root directory. May be required to
      #   load plugin.
      # @option options [String] :plugin_require_path The optional path to `require` to load the plugin.
      # @option options [String] :plugin_class_name The fully-qualified name of the plugin's class.
      # @return [void]
      # @see Corvid::Generator::PluginCli
      def start(options)
        options= options.dup
        plugin              = options.delete :plugin
        project_root        = options.delete :project_root
        plugin_require_path = options.delete :plugin_require_path
        plugin_class_name   = options.delete :plugin_class_name
        raise "Unknown options: #{options.keys}" unless options.empty?

        # Load CLI
        gen= ::Corvid::Generator::PluginCli

        # Load plugin
        plugin ||= load_plugin(project_root, plugin_require_path, plugin_class_name)
        raise "Invalid plugin: #{plugin.inspect}" unless plugin.is_a?(Corvid::Plugin)
        gen.plugin(plugin)

        # Customise CLI
        plugins= PluginRegistry.read_client_plugins || []
        gen.remove_task 'install' if     plugins.include? plugin.name
        gen.remove_task 'update'  unless plugins.include? plugin.name

        # Start CLI
        gen.start
      end

      # Loads a plugin and creates a new instance.
      #
      # @param [String] project_root The full path of the plugin project's root directory.
      # @param [nil,String] plugin_require_path The optional path to `require` to load the plugin.
      # @param [String] plugin_class_name The fully-qualified name of the plugin's class.
      # @return [Plugin] A new plugin instance.
      def load_plugin(project_root, plugin_require_path, plugin_class_name)

        # Require plugin
        begin
          require plugin_require_path
        rescue LoadError
          # Add project's lib dir
          lib= File.expand_path File.join(project_root, 'lib')
          $:.unshift lib if Dir.exists? lib and not $:.include? lib
          require plugin_require_path
        end if plugin_require_path

        # Create plugin instance
        plugin_class= eval(plugin_class_name.sub /^(?!::)/,'::')
        plugin= plugin_class.new
      end

    end
  end
end
