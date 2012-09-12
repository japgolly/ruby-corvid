require 'corvid/feature'

module Corvid
  module Builtin
    class CorvidFeature < ::Corvid::Feature

      rake_tasks {
        require 'corvid/builtin/rake/tasks/clean'
        require 'corvid/builtin/rake/tasks/doc'
        require 'corvid/builtin/rake/tasks/stats'
        require 'corvid/builtin/rake/tasks/todo'
      }

    end
  end
end

