require 'corvid/feature'

module Corvid
  module Builtin
    class CorvidFeature < ::Corvid::Feature

      rake_tasks {
        require 'corvid/rake/tasks/clean'
        require 'corvid/rake/tasks/doc'
      }

    end
  end
end

