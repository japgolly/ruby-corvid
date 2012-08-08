require 'golly-utils/singleton'
require 'corvid/extension'
require 'corvid/feature_manager'

module Corvid
  class ExtensionRegistry
    include GollyUtils::Singleton

    # @!attribute feature_manager
    #   @return [FeatureManager]
    FeatureManager.def_accessor(self)

    def extensions
      @extensions ||= (
        # Add all extensions provided by installed features
        feature_manager.instances_for_installed.values.compact.select{|f| Extension === f }
      )
    end

    # Runs all extensions for a given extension point.
    #
    # @param [Symbol] name The extension point name. Must match the callbacks declared TODO in {Extension}.
    # @return [nil]
    def run_extensions_for(name)
      extensions.each do |ext|
        ext.run_callback name
      end
      nil
    end

  end
end

