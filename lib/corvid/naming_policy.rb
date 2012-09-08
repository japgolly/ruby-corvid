module Corvid
  # Provides various methods that validate and work with rules pertaining to feature and plugin names.
  module NamingPolicy

    PLUGIN_NAME_FMT= '[A-Za-z0-9_.@#$%^&()\\[\\]{}~-]+'.freeze
    PLUGIN_NAME_REGEX= /\A#{PLUGIN_NAME_FMT}\z/
    FEATURE_NAME_FMT= PLUGIN_NAME_FMT
    FEATURE_NAME_REGEX= /\A#{FEATURE_NAME_FMT}\z/
    FEATURE_ID_REGEX= /\A#{PLUGIN_NAME_FMT}:#{FEATURE_NAME_FMT}\z/

    # Validates that a feature name is legal.
    #
    # @param [String] feature_name The name of the feature (without a plugin prefix).
    # @return [nil]
    # @raise If the name is invalid.
    def validate_feature_name!(feature_name)
      unless feature_name.is_a? String
        raise "Invalid feature name: #{feature_name.inspect}. String expected."
      end
      unless FEATURE_NAME_REGEX === feature_name
        raise "Invalid feature name: '#{feature_name}'. Must match regex: #{FEATURE_NAME_REGEX}"
      end
      nil
    end

    # Validates that a plugin name is legal.
    #
    # @param [String] plugin_name The name of the plugin.
    # @return [nil]
    # @raise If the name is invalid.
    def validate_plugin_name!(plugin_name)
      unless plugin_name.is_a? String
        raise "Invalid plugin name: #{plugin_name.inspect}. String expected."
      end
      unless PLUGIN_NAME_REGEX === plugin_name
        raise "Invalid plugin name: '#{plugin_name}'. Must match regex: #{PLUGIN_NAME_REGEX}"
      end
      nil
    end

    # Validates that a feature id is legal.
    #
    # @param [String] feature_id The feature id to validate.
    # @return [nil]
    # @raise If the feaature id is invalid.
    def validate_feature_id!(feature_id)
      unless FEATURE_ID_REGEX === feature_id
        raise "Invalid feature id: '#{feature_id}'. Must be in the format of '<plugin name>:<feature name>'."
      end
      nil
    end

    # Validates multiple plugin names.
    #
    # @param [Array<String>] plugin_names Plugin names to validate.
    # @return [nil]
    # @raise If any names are invalid.
    def validate_plugin_names!(*plugin_names)
      plugin_names.flatten.each{|n| validate_plugin_name! n }
      nil
    end

    # Validates multiple feature names.
    #
    # @param [Array<String>] feature_names Feature names to validate.
    # @return [nil]
    # @raise If any names are invalid.
    def validate_feature_names!(*feature_names)
      feature_names.flatten.each{|n| validate_feature_name! n }
      nil
    end

    # Validates multiple feature ids.
    #
    # @param [Array<String>] feature_ids Feature ids to validate.
    # @return [nil]
    # @raise If any feature ids are invalid.
    def validate_feature_ids!(*feature_ids)
      feature_ids.flatten.each{|n| validate_feature_id! n }
      nil
    end

    # Generates a feature id.
    #
    # @param [String] plugin_name The name of the plugin that owns the feature.
    # @param [String] feature_name The name of the feature.
    # @return [String] A feature id.
    # @raise If the plugin or feature names are invalid.
    def feature_id_for(plugin_name, feature_name)
      validate_plugin_name! plugin_name
      validate_feature_name! feature_name
      "#{plugin_name}:#{feature_name}"
    end

    # Splits a feature id into plugin and feature names.
    #
    # @param [String] feature_id The feature id to parse.
    # @return [[String, String]] An array of two strings: plugin name and feature name respectively.
    # @raise If the feature id is invalid.
    def split_feature_id(feature_id)
      validate_feature_id! feature_id
      feature_id.split ':'
    end

  end
end
