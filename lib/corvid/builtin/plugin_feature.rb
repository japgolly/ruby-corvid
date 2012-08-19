require 'corvid/feature'

module Corvid
  module Builtin
    class PluginFeature < ::Corvid::Feature

      since_ver 2

      requirements 'corvid:corvid'

      rake_tasks {
        require 'corvid/rake/tasks/resources'
      }

    end
  end
end

