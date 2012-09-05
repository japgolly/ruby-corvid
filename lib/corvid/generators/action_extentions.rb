require 'corvid/gemfile_evaluator'

module Corvid
  module Generator

    # Provides additional actions, and extentions to Thor actions.
    module ActionExtentions

      # Name of the option that users can use on the CLI to opt-out of Bundler being run at the end of certain tasks.
      RUN_BUNDLE= :'run_bundle'

      # Copies a file and gives it 755 permissions.
      # @return [void]
      def copy_executable(name, *extra_args)
        copy_file name, *extra_args
        chmod name, 0755, *extra_args
      end

      # Calls `copy_file` unless the file already exists.
      # @return [void]
      def copy_file_unless_exists(src, tgt=nil, options={})
        tgt ||= src
        copy_file src, tgt, options unless File.exists?(tgt)
      end

      # Reads a boolean option and if it hasn't been specified on the command-line, then prompts the user to decide.
      #
      # @param [String,Symbol] option_name The name of the Thor option.
      # @param [String] question The text to display to the user (include your own question mark) when prompting them
      #   to enter y/n.
      # @return [Boolean]
      def boolean_specified_or_ask(option_name, question)
        v= options[option_name.to_sym]
        v or v.nil? && yes?(question + ' [yn]')
      end

      # Adds a line of text to a file.
      #
      # * If the file already contains the line of text, nothing happens.
      # * If the file doesn't exist, it is created.
      #
      # @param [String] file The file to update.
      # @param [String] line The line of text to insert. (Don't include any carriage returns.)
      # @return [Boolean] `true` if file updated, else `false`.
      def add_line_to_file(file, line)
        updated= false
        if File.exists?(file)
          file_contents= File.read(file)
          unless file_contents[line]
            repl= "\r\n".include?(file_contents[-1]) ? "#{line}\n" : "\n#{line}"
            insert_into_file file, repl, before: /\z/
            updated= true
          end
        else
          create_file file, line
          updated= true
        end

        updated
      end

      # Easier way of calling Thor's `template` method.
      #
      # @note Ensure that you call {#with_action_context} first if methods used to resolve template variables are in a
      #   different context.
      #
      # @example
      #   template2 'lib/%name%.rb.tt'
      #   template2 'bin/%exec_name%.tt', perms: 0755
      #
      # @param [String] file The filename of the template. Normally ends in `.tt`.
      # @param [Hash] options
      # @option options [Fixnum] :perms (nil) The desired permissions (in octal) of the target file.
      # @return [void]
      # @see #with_action_context
      def template2(file, options={})
        src= file

        # Parse options
        perms= options.delete :perms
        raise "Unsupported options specified: #{options.inspect}" unless options.empty?

        # Substitute tags in filename
        target= file.sub /\.tt$/, ''
        target.scan(/%.+?%/).uniq.each do |tag|
          value= action_context.send tag[1..-2].to_sym
          target.gsub! tag, value.to_s
        end

        # Create file
        template src, target
        chmod target, perms if perms
      end

      # Monkey patch of Thor's `template` method.
      #
      # Changed to use the {#action_context} binding rather than the generator binding.
      #
      # @note Ensure that you call {#with_action_context} first if methods used to resolve template variables are in a
      #   different context.
      #
      # @see #with_action_context
      def template(source, *args, &block)
        config = args.last.is_a?(Hash) ? args.pop : {}
        destination = args.first || source.sub(/\.tt$/, '')

        source  = File.expand_path(find_in_source_paths(source.to_s))
        #context = instance_eval('binding')
        context = action_context.instance_eval('binding') # <---- monkey patch

        create_file destination, nil, config do
          content = ERB.new(::File.binread(source), nil, '-', '@output_buffer').result(context)
          content = block.call(content) if block
          content
        end
      end

      # Uses a provided action context for the duration of the block.
      #
      # What is an action context? It is an object that will be used by functions in this module that need to run
      # `instance_eval` to call expected methods. The reason this is required in the context of Corvid specifically, is
      # that feature installers are created as new objects that delegate to generators, meaning that methods locally
      # defined in feature installers are not available to the generator itself. This is desired for isolation and
      # safety yet causes {#template} and {#template2} to fail when attempting to resolve template variables. Therefore
      # by providing the feature installer as the action context, said methods will resolve required variables through
      # the action context (i.e. specific feature installer) rather than the generator.
      #
      # @example Feature installer
      #   install {
      #     template2 '%name%.rb.tt'
      #   }
      #
      #   def name  # <-- This method will not be available from the generator.
      #     'blah'
      #   end
      #
      # @example Using the action context
      #   feature_installer.install                         # Fails because name() isn't available from generator.
      #   with_action_context feature_installer, &:install  # Passes because name() is available from action ctx.
      #
      # @param [Object] action_ctx The object to use as the action context. Normally a feature installer.
      # @yieldparam [Object] action_ctx The provided action context.
      # @return [Object] The result of the given block.
      def with_action_context(action_ctx)
        old_action_ctx= @action_ctx
        begin
          @action_ctx= action_ctx
          return yield action_ctx
        ensure
          @action_ctx= old_action_ctx
        end
      end

      # Returns the current action context, or `self` if it hasn't been set.
      #
      # @return [Object|self] Never `nil`.
      def action_context
        @action_ctx || self
      end

      # Adds a new dependency to `Gemfile`.
      #
      # If the dependency is already declared, even if the parameters differ, then it will be left as is without making
      # changes.
      #
      # @example
      #   add_dependency_to_gemfile 'rake', '>= 0.9', require: false
      #
      # @param [String|Array] args The args that should be passed to the `gem` DSL command in the `Gemfile`.
      # @return [void]
      # @see #add_dependencies_to_gemfile
      def add_dependency_to_gemfile(*args)
        add_dependencies_to_gemfile args # Note this is deliberately not *args
      end

      # Adds new dependencies to `Gemfile`.
      #
      # If a dependency is already declared, even if the parameters differ, then it will be left as is without making
      # changes.
      #
      # @example
      #   add_dependencies_to_gemfile 'minitest', 'guard-minitest'
      #   add_dependencies_to_gemfile ['rake', '>= 0.9', require: false], 'yard'
      #
      # @param [Array<String|Array>] args An array of args that should be passed to the `gem` DSL command in the
      #   `Gemfile`.
      # @return [void]
      # @see #add_dependency_to_gemfile
      def add_dependencies_to_gemfile(*args)
        gemfile= 'Gemfile'
        content= File.read(gemfile)

        ge= ::Corvid::GemfileEvaluator.new.eval_string(content)
        args.each do |name, *dep_args|
          name= name.to_s if name.is_a?(Symbol)
          raise "Invalid dependency name: #{name.inspect}" unless name.is_a?(String)
          unless ge.gems.has_key? name
            line= "gem #{name.inspect}"
            unless dep_args.empty?
              o= dep_args.last.is_a?(Hash) ? dep_args.pop : nil
              line+= dep_args.map{|d| ", #{d.inspect}"}.join
              line+= o.map{|k,v| ", #{k}: #{v.inspect}"}.join if o
            end

            content.sub! /\n?\z/, "\n"
            content+= line
          end
        end

        create_file gemfile, content, force: true
      end

      # Unless the option to disable this specifies otherwise, asynchronously sets up `bundle install` to run in the
      # client's project after all generators have completed.
      #
      # @return [void]
      def run_bundle_at_exit
        return if $corvid_bundle_install_at_exit_installed
        return if options[RUN_BUNDLE] == false

        if options[RUN_BUNDLE].nil?
          STDERR.puts "[WARNING] run_bundle_at_exit() called without Thor option to disable it.\n#{caller.join "\n"}\n#{'-'*80}\n\n"
        end

        $corvid_bundle_install_at_exit_installed= true
        at_exit {
          ENV['BUNDLE_GEMFILE']= nil
          ENV['RUBYOPT']= nil
          run "bundle install"
        }
      end

      #-----------------------------------------------------------------------------------------------------------------

      # @!visibility private
      def self.included(target)
        target.extend ClassMethods
      end

      module ClassMethods

        # @!visibility private
        RUN_BUNDLE= ActionExtentions::RUN_BUNDLE

        # Declares a Thor option that allows users to opt-out of Bundler being run at the end of certain tasks.
        #
        # @param [Base] g The generator in which to delcare the option.
        # @return [void]
        # @see Corvid::Generator::ActionExtentions::RUN_BUNDLE
        # @see #run_bundle_at_exit
        def declare_option_to_run_bundle_at_exit(g)
          g.method_option RUN_BUNDLE, type: :boolean, default: true, optional: true
        end

      end
    end
  end
end
