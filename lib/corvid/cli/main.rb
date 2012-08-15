require 'thor'

module Corvid
  module CLI
    module Main
      extend self

      def start

        # Load generators
        require 'corvid/generators/init'
        require 'corvid/generators/new'
        require 'corvid/generators/update'

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
