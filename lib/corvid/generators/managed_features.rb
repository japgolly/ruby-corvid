require 'corvid/generators/base'
require 'corvid/naming_policy'

module Corvid::Generator::ManagedFeatures
  include Corvid::NamingPolicy
  extend self

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
