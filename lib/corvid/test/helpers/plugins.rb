require 'corvid/constants'
require 'corvid/plugin'
require 'yaml'

module Corvid
  module PluginTestHelpers

    def assert_features_installed(*expected)
      client_features.should equal_array expected.flatten
    end

    def assert_plugins_installed(expected_names_or_hash)
      f= client_plugins
      if expected_names_or_hash.is_a?(Array)
        f.keys.should equal_array expected_names_or_hash
      else
        f.should == expected_names_or_hash
      end
    end

    def client_features
      Constants::FEATURES_FILE.should exist_as_file
      f= YAML.load_file(Constants::FEATURES_FILE)
      f.should be_kind_of(Array)
      f
    end

    def client_plugins
      Constants::PLUGINS_FILE.should exist_as_file
      f= YAML.load_file(Constants::PLUGINS_FILE)
      f.should be_kind_of(Hash)
      f
    end

    def add_feature!(feature_id)
      f= File.exists?(Constants::FEATURES_FILE) ? YAML.load_file(Constants::FEATURES_FILE) : []
      f<< feature_id
      Dir.mkdir '.corvid' unless Dir.exists? '.corvid'
      File.write Constants::FEATURES_FILE, f.to_yaml
    end

    def add_plugin!(plugin)
      p= File.exists?(Constants::PLUGINS_FILE) ? YAML.load_file(Constants::PLUGINS_FILE) : {}
      plugin= plugin.new if plugin.is_a?(Class)
      case plugin
      when Corvid::Plugin
        p[plugin.name]= {path: plugin.require_path, class: plugin.class.to_s}
      when String
        p[plugin]= {class: 'fake'}
      when Hash
        p.merge! plugin
      else
        raise "Invalid plugin param: #{plugin.inspect}"
      end
      Dir.mkdir '.corvid' unless Dir.exists? '.corvid'
      File.write Constants::PLUGINS_FILE, p.to_yaml
    end

    def add_version!(plugin, version)
      vers= File.exists?(Constants::VERSIONS_FILE) ? YAML.load_file(Constants::VERSIONS_FILE) : {}
      plugin= plugin.name if plugin.is_a?(Corvid::Plugin)
      if version
        vers[plugin]= version
      else
        vers.delete plugin
      end
      Dir.mkdir '.corvid' unless Dir.exists? '.corvid'
      File.write Constants::VERSIONS_FILE, vers.to_yaml
    end

    def generator_config(quiet)
      # Quiet stdout - how the hell else are you supposed to do this???
      config= {}
      config[:shell] ||= Thor::Base.shell.new
      if quiet
        config[:shell].instance_eval 'def say(*) end'
        config[:shell].instance_eval 'def quiet?; true; end'
        #config[:shell].instance_variable_set :@mute, true
      end
      config
    end

    def quiet_generator(generator_class, cli_args=[])
      config= generator_config(true)
      g= generator_class.new(cli_args, [], config)
      decorate_generator g
    end

    def decorate_generator(g)
      # Use a test res-patch manager if available
      g.instance_variable_set :@rpms, @rpms if @rpms
      g
    end

  end
end
