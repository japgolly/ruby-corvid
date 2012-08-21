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

    # @!attribute [rw] requirements
    #   Requirements that must be satisfied before the plugin can be installed.
    #   @return [nil, String, Hash<String,Fixnum|Range|Array<Fixnum>>, Array] Requirements that can be provided to
    #     {RequirementValidator}.
    #   @see RequirementValidator#add
    attr_declarative :requirements

    # @!attribute [rw] feature_manifest
    #   A manifest of all features provided by the plugin.
    #   @return [Hash<String,Array<String>>] A hash with keys being feature names, and the values being a 2-element
    #     array of the feature's require-path, and class name, respectively.
    attr_declarative feature_manifest: {}

    # @!attribute [rw] auto_install_features
    #   A list of features to install automatically when the plugin itself is installed.
    #   @return [Array<String>] An array of feature names. Do not include the plugin prefix.
    attr_declarative auto_install_features: []

  end
end
