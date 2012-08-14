require 'golly-utils/attr_declarative'

module Corvid
  class Plugin
    # Plugins can be extensions but are not by default.
    # include Extension

    # @!attribute [rw] name
    #   The name of the plugin. Must conform to format enforced by {Corvid::NamingPolicy#validate_plugin_name!}.
    #   @return [String] The plugin name.
    attr_declarative :name, required: true

    # @!attribute [rw] require_path
    #   The path for Ruby to `require` in order to load this plugin.
    #   @return [String] The path to require, usually relative to your `lib` dir.
    attr_declarative :require_path, required: true

    # @!attribute [rw] resources_path
    #   The path to the directory containing the plugin's resources.
    #   @return [String] An absolute path.
    attr_declarative :resources_path, required: true

    # @!attribute [rw] feature_manifest
    #   A manifest of all features provided by the plugin.
    #   @return [Hash<String,Array<String>>] A hash with keys being feature names, and the values being a 2-element
    #     array of the feature's require-path, and class name, respectively.
    attr_declarative feature_manifest: {}

  end
end
