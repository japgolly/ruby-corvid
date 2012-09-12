require 'corvid/feature'

module Corvid
  module Builtin
    class CorvidFeature < ::Corvid::Feature

      rake_tasks {
        require 'corvid/builtin/rake/tasks/clean'
        require 'corvid/builtin/rake/tasks/doc'
        require 'corvid/builtin/rake/tasks/stats'
      }

    end
  end
end

