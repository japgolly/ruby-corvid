require 'corvid/feature'

module Corvid
  module Builtin
    class TestUnitFeature < ::Corvid::Feature

      requirements 'corvid:corvid'

      rake_tasks {
        require 'corvid/rake/tasks/test'
      }

    end
  end
end

