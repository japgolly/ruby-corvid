require 'corvid/generator/base'
require 'corvid/naming_policy'

# Provides common tasks and functionality for features that don't have any special or custom requirements.
module Corvid::Generator::ManagedFeatures
  include Corvid::NamingPolicy
  extend self

  # Creates a new Thor task that will install a given feature.
  #
  # @param [String] feature_id The ID of the feature that will be installed when the task is invoked.
  # @return [void]
  def create_install_task_for(feature_id)
    class_name= "::ManagedFeatureTask#{@@managed_features += 1}"
    plugin_name,feature_name = split_feature_id(feature_id)

    eval <<-EOB
      class #{class_name} < ::Corvid::Generator::Base
        namespace '#{plugin_name}:install'

        desc '#{feature_name}', 'Installs the #{feature_name} feature.'
        # declare_option_to_run_bundle_at_exit(self)
        def #{feature_name}
          install_feature '#{plugin_name}', '#{feature_name}'
        end
      end

      #{class_name}
    EOB
  end

  private
  @@managed_features= 0
end
