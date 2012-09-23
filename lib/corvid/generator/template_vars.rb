module Corvid
  module Generator

    # Provides methods returning values that will primarily be used in templates.
    module TemplateVars
      extend self

      # Clears all cached template values defined in this module.
      #
      # @return [self]
      def reset_template_var_cache
        @@template_var_project_name= nil
        self
      end

      # Evaluates all cachable template values.
      #
      # @return [self]
      def preload_template_vars
        project_name
        self
      end

      # Guesses the name of the project in the current directory.
      #
      # Infers the project name from the following, in order of precedence.
      #
      # 1. The name of the one and only subdirectory of `lib`.
      # 2. The filename of the one and only file matching `*.gemspec` in the current directory, minus the file
      #    extension.
      # 3. The name of the current directory.
      #
      # @example
      #   lib/hello       # <= uses 'hello'
      #
      #   orange.gemspec  # <= uses 'orange'
      #
      #   pwd             # <= returns /home/myname/projects/crazy_app
      #                   # uses 'crazy_app'
      #
      # @note Because this value is determined by inspecting the state of the current directory, it is cached globally
      #   so that it remains consistent as the current directory tree state changes. Use {#reset_template_var_cache} to
      #   clear the cache.
      #
      # @return [String] Guess at the project name.
      def project_name
        @@template_var_project_name ||= (

          # Look for single lib/ dir
          if (dirs= Dir['lib/*'].select{|d| File.directory? d }).size == 1
            File.basename dirs[0]

          # *.gemspec
          elsif (gemspecs= Dir['*.gemspec'].select{|f| File.file? f }).size == 1
            File.basename(gemspecs[0]).sub /\.gemspec$/, ''

          # pwd
          else
            File.basename Dir.pwd

          end
        )
      end

      # The Ruby module name of the current project.
      #
      # @example
      #   project_name    # <= "crazy_app"
      #   project_module  # <= "CrazyApp"
      #
      # @return [String] The name of the project module.
      def project_module
        project_name.gsub('-','_').camelize
      end

      # Guesses the current user's full name.
      #
      # @return [nil|String] The current user's full name or `nil` if unable to determine.
      def author_name
        read_git_config_value 'user.name'
      end

      # Guesses the current user's email address.
      #
      # @return [nil|String] An email address or `nil` if unable to determine.
      def author_email
        read_git_config_value 'user.email'
      end

      # Takes a name that could potentially be a project lib filename, and strips it down to a name.
      #
      # @example
      #   'lib/my_project/engine/core.rb'  # => 'engine/core'
      #   'my_project/engine/core.rb'      # => 'engine/core'
      #   'lib/engine/core.rb'             # => 'engine/core'
      #   'engine/core.rb'                 # => 'engine/core'
      #   'engine/core'                    # => 'engine/core'
      #   'core.rb'                        # => 'core'
      #   'core'                           # => 'core'
      #   'MyStuff'                        # => 'my_stuff'
      #
      # @param [String] name The given name.
      # @return [String]
      def preprocess_template_name_arg(name)
        name
          .gsub(/^[\\\/]+|\.rb$/,'')
          .sub(/^lib[\\\/]+/,'')
          .underscore
          .sub(/^#{Regexp.quote project_name.underscore}[\\\/]+/,'')
      end

      private

      def read_git_config_value(name)
        v= `git config --get #{name}`.chomp rescue nil
        $?.success? && !v.empty? ? v : nil
      end

    end
  end
end
