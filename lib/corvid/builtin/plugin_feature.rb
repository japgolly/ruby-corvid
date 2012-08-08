require 'corvid/feature'

module Corvid
  module Builtin
    class PluginFeature < ::Corvid::Feature

      rake_tasks {
        require 'corvid/rake/tasks/resources'
      }

    end
  end
end

