require 'corvid/feature'

module Corvid
  module Builtin
    class TestSpecFeature < ::Corvid::Feature

      rake_tasks {
        require 'corvid/builtin/rake/tasks/test'
      }

    end
  end
end

