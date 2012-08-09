require 'corvid/feature'

module Corvid
  module Builtin
    class PluginFeature < ::Corvid::Feature

      since_ver 2

      rake_tasks {
        require 'corvid/rake/tasks/resources'
      }

    end
  end
end

