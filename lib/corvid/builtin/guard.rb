# This is meant to be called from Guardfile directly.
require 'golly-utils/ruby_ext/env_helpers'

module Corvid
  module Builtin
    # This module provides methods to be used in a `Guardfile`.
    #
    # @example `Guardfile` content:
    #     require 'corvid/builtin/guard'
    #
    #     ignore VIM_SWAP_FILES
    #
    #     rspec_options = read_rspec_options(File.dirname __FILE__)
    #     guard 'rspec', binstubs: true, spec_paths: ['test/spec'], cli: rspec_options do
    #       watch(%r'^test/spec/.+_spec\.rb$')
    #     end
    module GuardExt

      # Checks the environment variable `'bulk'`. Defaults to `true` if unspecified.
      #
      # @return [Boolean] `true` if `bulk` set to positive or unspecified, else `false` if set to negative.
      def bulk?; ENV.on?('bulk',true) end

      # Checks the environment variable `'fast'`. Defaults to `false` if unspecified.
      #
      # @return [Boolean] `true` if `fast` set to positive, else `false`.
      def fast_only?; ENV.on?('fast') end

      # Parses a project's `.rspec` file and makes the following modifications.
      #
      # 1. Removes comments
      # 2. Joins lines.
      # 3. Changes random test order into default order.
      # 4. Excludes tests with the tag `slow` if {#fast_only?} is on.
      #
      # @param [String] app_root The project root directory.
      # @return [nil|String] `nil` if the file doesn't exist, else the contents of the file.
      def read_rspec_options(app_root)

        rspec_cfg= "#{app_root}/.rspec"
        r= if File.exists?(rspec_cfg)
             File.read(rspec_cfg)
                 .gsub(/#.+?(?:[\r\n]|$)/,' ')                    # Remove comments
                 .gsub(/\s+/,' ')                                 # Join lines and normalise spaces
                 .gsub(/-(O|-order) rand(om)?/,'--order default') # Disable random order when using Guard
                 .gsub(/^\s+|\s+$/,'')                            # Trim beginning/end whitespace
             else
               nil
             end

        # Disable slow tests in fast-mode
        if fast_only?
          r= [r,'--tag ~slow'].compact.join ' '
        end

        r
      end

      # Attemps to determine the project name.
      #
      # @return [String] A guess at the project name.
      def determine_project_name
        require 'corvid/generator/template_vars'
        Corvid::Generator::TemplateVars.project_name
      end

      # Regex that matches swap files that Vim creates.
      VIM_SWAP_FILES= /^(?:(?:.*[\\\/])?\.[^\\\/]+\.sw[p-z]|.+~)$/

    end
  end
end

include Corvid::Builtin::GuardExt unless $weave_corvid_guard_ext == false
