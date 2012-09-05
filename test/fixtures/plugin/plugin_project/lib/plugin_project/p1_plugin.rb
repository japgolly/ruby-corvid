require 'corvid/plugin'
require 'corvid/extension'

module PluginProject
  class P1Plugin < Corvid::Plugin
    include Corvid::Extension

    # The name of the plugin. Must conform to format enforced by {Corvid::NamingPolicy#validate_plugin_name!}.
    #
    # @return [String] The plugin name.
    name 'p1'

    # The path for Ruby to require in order to load this plugin.
    #
    # @return [String] The path to require, usually relative to your lib dir.
    require_path 'plugin_project/p1_plugin'

    # The path to the directory containing the plugin's resources.
    #
    # @return [String] An absolute path.
    resources_path File.expand_path('../../../resources', __FILE__)

    # A manifest of all features provided by the plugin.
    #
    # @return [Hash<String,Array<String>>] A hash with keys being feature names, and the values being a 2-element
    #   array of the feature's require-path, and class name, respectively.
    feature_manifest ({
      'f1' => ['plugin_project/f1_feature','::PluginProject::F1Feature'],
    })

    # Callback that is run after the plugin is installed.
    #
    # Generator actions are available and can be invoked as if the callback function were a generator method.
    after_installed {
      add_dependency_to_gemfile 'plugin_project'
    }

    # A list of features to install automatically when the plugin itself is installed.
    #
    # @return [Array<String>] An array of feature names. Do not include the plugin prefix.
    auto_install_features %w[]

    # Rake tasks
    rake_tasks {
      extend Rake::DSL

      namespace :p1 do
        desc 'Generate hello.txt'
        task :hello do
          File.write 'hello.txt', 'Created by p1'
        end
      end
    }

  end
end
