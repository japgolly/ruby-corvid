require 'golly-utils/singleton'
require 'corvid/extension'
require 'corvid/feature_registry'
require 'corvid/plugin_registry'

module Corvid
  # Maintains a registry of {Extension extensions}.
  #
  # When a part of Corvid allows external customisation, it uses the singleton instance of this class to call
  # {#run_extensions_for} with the extension point (i.e. callback/hook) name. As long as a callback is defined in
  # {Extension} with the extension point name, the corresponding callback procs supplied by all registered extensions
  # will be invoked in turn.
  #
  # By default, extensions are discovered and registered automatically by getting all installed features from
  # {FeatureRegistry} and plugins from {PluginRegistry}, then collecting those that include {Extension}.
  #
  # @see Extension
  class ExtensionRegistry
    include GollyUtils::Singleton

    # @!attribute [rw] feature_registry
    #   @return [FeatureRegistry]
    FeatureRegistry.def_accessor(self)

    # @!attribute [rw] plugin_registry
    #   @return [PluginRegistry]
    PluginRegistry.def_accessor(self)

    # Returns all registered extensions.
    #
    # If no extensions have been registered, then {#auto_discover} is called first.
    #
    # @return [Array<Extension>] All registered extensions.
    def extensions
      auto_discover if !@extensions
      @extensions.dup
    end

    # Looks for extensions by collecting features from {FeatureRegistry} and plugins from {PluginRegistry} that include
    # {Extension}, then registers all found.
    #
    # @return [self]
    def auto_discover
      # Add all extensions provided by installed plugins
      register plugin_registry.instances_for_installed.values

      # Add all extensions provided by installed features
      register feature_registry.instances_for_installed.values

      self
    end

    # Registers supplied extensions.
    #
    # Invalid arguments such as `nil`s and classes that don't implement {Extension}, will be discarded.
    #
    # @overload register(extension)
    #   @param [Extension] extension The extension to register.
    # @overload register(*extensions)
    #   @param [Array<Extension>] extensions The extensions to register.
    # @return [self]
    def register(*extensions)
      @extensions ||= []
      extensions
        .flatten
        .compact
        .select{|f| Extension === f }
        .each {|ext| @extensions<< ext unless @extensions.include? ext }
      self
    end

    # Runs all callback procs supplied by all registered extensions for a given extension point (i.e. callback/hook)
    # name.
    #
    # @param [Symbol] name The extension point name. Must match the name of one of the callbacks declared {Extension}.
    # @return [nil]
    def run_extensions_for(name)
      extensions.each do |ext|
        ext.run_callback name
      end
      nil
    end

  end
end

