require 'corvid/feature'

module Corvid
  module Builtin
    class TestUnitFeature < ::Corvid::Feature

      rake_tasks {
        require 'corvid/builtin/rake/tasks/test'
      }

    end
  end
end

