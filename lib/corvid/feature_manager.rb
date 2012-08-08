require 'golly-utils/singleton'
require 'corvid/constants'
require 'corvid/builtin/manifest'

module Corvid
  class FeatureManager
    include GollyUtils::Singleton

    def initialize
      clear_cache
    end

    def clear_cache
      @feature_manifest= nil
      @instance_cache= {}
      @instances_for_installed= nil
      self
    end

    def self.def_accessor(target)
      # Not using attr_writer here cos of Thor.no_tasks
      target.class_eval <<-EOB
        def feature_manager
           @feature_manager ||= ::#{self}.instance
        end
        def feature_manager=(fm)
           @feature_manager= fm
        end
      EOB
    end

    # Reads and parses the contents of the client's {Constants::FEATURES_FILE FEATURES_FILE} if it exists.
    #
    # @return [nil,Array<String>] A list of features or `nil` if the file wasn't found.
    def read_client_features
      if File.exists? Constants::FEATURES_FILE
        v= YAML.load_file Constants::FEATURES_FILE
        raise "Invalid #{Constants::FEATURES_FILE}. Array expected but got #{v.class}." unless v.is_a?(Array)
        raise "Invalid #{Constants::FEATURES_FILE}. At least 1 feature expected but not defined." if v.empty?
        v
      else
        nil
      end
    end

    # Reads and parses the contents of the client's {Constants::FEATURES_FILE FEATURES_FILE}.
    #
    # @return [Array<String>] A list of features.
    # @raise If file not found.
    # @see #read_client_features
    def read_client_features!
      features= read_client_features
      raise "File not found: #{Constants::FEATURES_FILE}\nYou must install Corvid first. Try corvid init:project." if features.nil?
      features
    end

    # @return [Hash<String,nil|String>]
    def feature_manifest
      if @feature_manifest.nil?
        @feature_manifest= {}

        # Register built-in features
        register_features Corvid::Builtin::Manifest.new.feature_manifest

      end
      @feature_manifest
    end

    # @param [String] name
    # @return [nil,Feature]
    def instance_for(name)
      return @instance_cache[name] if @instance_cache.has_key?(name)

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

      @instance_cache[name]= instance
    end

    # TODO
    #
    # @param [Boolean] force If enabled, then the cached value will be discarded.
    # @return [Hash<String,nil|Feature>] An instance of each client-installed feature. May return an empty array but never `nil`.
    def instances_for_installed#(force=false)
#      @instances_for_installed= nil if force
      @instances_for_installed ||= (
        (read_client_features || []).inject({}) {|h,f| h[f]= instance_for f; h }
      )
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
