require 'corvid/extension_registry'
require 'corvid/feature_registry'
require 'corvid/generators/managed_features'
require 'thor'

module Corvid
  module CLI
    module Main
      extend self

      def start

        features= FeatureRegistry.read_client_features

        # Check if Corvid installed yet
        if features.nil?
          require 'corvid/generators/init/corvid'
          Generator::InitCorvid.start

        else
          # Load internal tasks
          require 'corvid/generators/init/plugin'    unless features.include? 'corvid:plugin'
          require 'corvid/generators/init/test_unit' unless features.include? 'corvid:test_unit'
          require 'corvid/generators/init/test_spec' unless features.include? 'corvid:test_spec'
          require 'corvid/generators/new/plugin'     if     features.include? 'corvid:plugin'
          require 'corvid/generators/new/feature'    if     features.include? 'corvid:plugin'
          require 'corvid/generators/new/unit_test'  if     features.include? 'corvid:test_unit'
          require 'corvid/generators/new/spec'       if     features.include? 'corvid:test_spec'
          require 'corvid/generators/update'
          Generator::Update.add_tasks_for_installed_plugins!

          # Load external tasks
          ExtensionRegistry.run_extensions_for :corvid_tasks

          # Create install tasks for uninstalled features
          FeatureRegistry.feature_manifest.keys.each do |feature_id|
            next if feature_id =~ /^corvid:/ # TODO corvid builtin features should be weaved in via plugin arch
            next if features.include? feature_id
            next unless f= FeatureRegistry[feature_id]
            next unless f.managed_install_task?
            Generator::ManagedFeatures.create_install_task_for feature_id
          end

          # Show available tasks by default
          ARGV<< '-T' if ARGV.empty?

          # Pass control to Thor's runner
          require 'thor/runner'
          $thor_runner = true
          Thor::Runner.start
        end
      end

    end
  end
end
