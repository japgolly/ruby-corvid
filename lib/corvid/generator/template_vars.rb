module Corvid
  module Generator

    # Provides methods that returns values that will primarily be used in templates.
    module TemplateVars
      extend self

      # Clears all cached template values defined in this module.
      #
      # @return [self]
      def reset_template_var_cache
        @@template_var_project_name= nil
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
          dirs= Dir['lib/*'].select{|d| File.directory? d }
          return File.basename dirs[0] if dirs.size == 1

          # *.gemspec
          gemspecs= Dir['*.gemspec'].select{|f| File.file? f }
          return File.basename(gemspecs[0]).sub /\.gemspec$/, '' if gemspecs.size == 1

          # pwd
          File.basename Dir.pwd
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

      private

      def read_git_config_value(name)
        v= `git config --get #{name}`.chomp rescue nil
        $?.success? && !v.empty? ? v : nil
      end

    end
  end
end
