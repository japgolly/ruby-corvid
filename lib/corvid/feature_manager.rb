require 'golly-utils/singleton'
require 'corvid/builtin/manifest'

module Corvid
  class FeatureManager
    include GollyUtils::Singleton

    def initialize
      @cache= {}
    end

    # @param [String] name
    # @return [nil,Feature]
    def instance_for(name)
      return @cache[name] if @cache.has_key?(name)
      raise "Unknown feature: #{name}. It isn't specified in any manifests." unless feature_manifest.has_key?(name)

      data= feature_manifest[name]
      instance= if data
          # Create a new instance
          path,class_name = data
          require path
          klass= eval(class_name.sub /^(?!::)/,'::')
          klass.new
        else
          nil
        end

      @cache[name]= instance
    end

    # @return [Hash<String,nil|String>]
    def feature_manifest
      unless @feature_manifest
        @feature_manifest= {}
        register_features Corvid::Builtin::Manifest.new.feature_manifest
      end
      @feature_manifest
    end

    private

    # @param [Hash<String|Symbol, Array<String>] Feature manifest for a single plugin. See {#register_feature} for key
    #   and value explanations.
    def register_features(feature_hash)
      feature_hash.each do |name, data|
        register_feature name, data
      end
    end

    # @param [String, Symbol] name The feature name.
    # @param [nil, Array<String>] data An array of the require-path, and class name of the feature.
    def register_feature(name, data)

      # Check name
      name= name.to_s if name.is_a?(Symbol)
      STDERR.puts "WARNING: Feature '#{name}' already registered." if @feature_manifest.has_key?(name)

      # Check data
      unless data.nil? or data.is_a?(Array) && data[0].is_a?(String) && data[1].is_a?(String)
        raise "Invalid feature manifest value for #{name}.\nArray of [require_path, class_name] expected, got: #{data.inspect}"
      end

      # Register
      @feature_manifest[name]= data
    end

  end
end
