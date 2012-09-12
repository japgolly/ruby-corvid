require 'golly-utils/ruby_ext/kernel'
require 'corvid/gemfile_evaluator'

module Corvid
  module Generator

    # Provides additional actions, and extensions to Thor actions.
    module ActionExtensions

      # Name of the option that users can use on the CLI to opt-out of Bundler being run at the end of certain tasks.
      RUN_BUNDLE= :'run_bundle'

      # Copies a file and gives it 755 permissions.
      #
      # @param [String] name The name of the executable to copy.
      # @param extra_args Additional, optional arguments to pass to `copy_file` and `chmod` both.
      # @return [void]
      def copy_executable(name, *extra_args)
        copy_file name, *extra_args
        chmod name, 0755, *extra_args
      end

      # Calls `copy_file` unless the file already exists.
      #
      # @param [String] src The source file to copy.
      # @param [nil|String] tgt The target filename that will be created by the copy. `nil` indicates the filename is
      #   the same as the source filename.
      # @param [Hash] options Additional options to pass to `copy_file`.
      # @return [void]
      def copy_file_unless_exists(src, tgt=nil, options={})
        tgt ||= src
        copy_file src, tgt, options unless File.exists?(tgt)
      end

      # Reads a boolean-valued Thor option and if it hasn't been specified (usually via the command-line), then prompts
      # the user to provide an answer.
      #
      # @param [String|Symbol] option_name The name of the Thor option.
      # @param [String] question The text to display to the user (include your own question mark) when prompting the
      #   user to enter y/n.
      # @return [Boolean]
      def read_boolean_option_or_prompt_user(option_name, question)
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
        #context = instance_eval('binding')               # <---- monkey patch
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
      #   add_dependency_to_gemfile 'rake'
      #
      #   add_dependency_to_gemfile 'rake', '>= 0.9', require: false
      #
      #   add_dependency_to_gemfile 'rake', '>= 0.9', require: false, run_bundle_at_exit: false
      #
      # @overload add_dependency_to_gemfile(*args, options={})
      #   @param [String|Array] args The args that should be passed to the `gem` DSL command in the `Gemfile`.
      #   @param [Hash] options Supported options (see below) will be extracted, remaining options will be passed to
      #     the `gem` DSL command.
      #   @option options [Boolean] :run_bundle_at_exit (true) Whether or not to {#run_bundle_at_exit} if gems are
      #     successfully added to the `Gemfile`.
      # @return [Boolean] Whether or not the `Gemfile` was modified.
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
      #
      #   add_dependencies_to_gemfile ['rake', '>= 0.9', require: false], 'yard'
      #
      # @overload add_dependencies_to_gemfile(*deps, options={})
      #   @param [Array<String|Array>] deps An array of args that should be passed to the `gem` DSL command in the
      #     `Gemfile`. Each dep arg should be either a String, or an array of String with an optional Hash at the end.
      #   @option options [Boolean] :run_bundle_at_exit (true) Whether or not to {#run_bundle_at_exit} if gems are
      #     successfully added to the `Gemfile`.
      # @return [Boolean] Whether or not the `Gemfile` was modified.
      # @see #add_dependency_to_gemfile
      def add_dependencies_to_gemfile(*args)

        # Parse options if provided
        run_bundle_at_exit= nil
        o= args.pop.dup if args.last.is_a?(Hash)
        if o
          run_bundle_at_exit= o.delete :run_bundle_at_exit
          raise "Unknown options: #{o.inspect}" unless o.empty?
        end

        # Parse Gemfile
        gemfile= 'Gemfile'
        content= File.read(gemfile)
        ge= ::Corvid::GemfileEvaluator.new.eval_string(content)

        # Add deps
        dep_added= false
        args.each do |name, *dep_args|
          name= name.to_s if name.is_a?(Symbol)
          raise "Invalid dependency name: #{name.inspect}" unless name.is_a?(String)
          unless ge.gems.has_key? name

            # Add new dependency
            line= "gem #{name.inspect}"
            unless dep_args.empty?
              o= dep_args.last.is_a?(Hash) ? dep_args.pop : nil
              line+= dep_args.map{|d| ", #{d.inspect}"}.join
              if o
                if o.has_key? :run_bundle_at_exit
                  o= o.dup
                  run_bundle_at_exit= o.delete :run_bundle_at_exit
                end
                line+= o.map{|k,v| ", #{k}: #{v.inspect}"}.join
              end
            end
            content.sub! /\n?\z/, "\n"
            content+= line + "\n"
            dep_added= true
          end
        end

        # Create file (if no changes then Thor's create_file() will simply report as much)
        create_file gemfile, content, force: true

        # Run bundle
        if dep_added and run_bundle_at_exit || run_bundle_at_exit.nil?
          run_bundle_at_exit()
        end

        dep_added
      end

      # Unless the option to disable this specifies otherwise, asynchronously sets up `bundle install` to run in the
      # client's project after all generators have completed.
      #
      # @return [void]
      def run_bundle_at_exit
        return if $corvid_bundle_install_at_exit_installed
        return if options[RUN_BUNDLE] == false

        if options[RUN_BUNDLE].nil?
          STDERR.puts "[WARNING] run_bundle_at_exit() called without there being a Thor option to disable it.\n#{caller.join "\n"}\n#{'-'*80}\n\n"
        end

        $corvid_bundle_install_at_exit_installed= true
        at_exit_preserving_exit_status {
          ENV['BUNDLE_GEMFILE']= nil
          ENV['RUBYOPT']= nil
          run "bundle install"
        }
      end

      # Updates a gemspec file so that it declares one or more given names, as executables.
      #
      # This will do a bunch of regex magic and try to handle a bunch of predetermined scenarios, but in the event that
      # this function doesn't know how to (relatively-)safely make the required changes, the users will be promted to
      # update the file manually and this function will return `false`.
      #
      # @param [String] gemspec_file The filename of the gemspec to update.
      # @return [Boolean] Whether or not the gemspec was updated. `false` if the user was asked to update manually.
      # @raise If the file doesn't exist.
      def add_executable_to_gemspec(gemspec_file, *executable_names)

        # Validate exe names
        executable_names= executable_names.flatten.uniq
        return true if executable_names.empty?
        executable_names.each{|n| raise "Invalid name: #{n.inspect}. Only Strings are allowed." unless String === n }

        # Read and parse gemspec
        content= File.read(gemspec_file)
        gem_var, gem_block_opener, gem_block_closer, gem_block_closer_regex = nil
        if content =~ /Gem::Specification.*?(#{BLOCK_OPENERS_REGEX_STR})\s*?\|\s*?(\S+?)\s*?\|/m
          gem_block_opener , gem_var = $1,$2
          gem_block_closer= BLOCK_CLOSERS[gem_block_opener][:str]
          gem_block_closer_regex= BLOCK_CLOSERS[gem_block_opener][:regex]
        end

        new_content= nil

        # Handle case where it isn't defined at all
        if gem_var and content !~ /\n[^\n#]+?\.executables\s*=/
          new_line= "#{gem_var}.executables = #{executable_names.inspect}"
          new_content= append_to_code_block(new_line, content, gem_block_closer, gem_block_closer_regex)

        # Handle case where it is a plain array
        elsif /\n[^\n#]+?\.executables\s*=\s*\[/ === content
          end_char= ']'
          new_content= content.sub /(\n[^\n#]+?\.executables\s*=\s*\[)(.*?)#{Regexp.quote end_char}/m do
            start,mid = $1,$2
            mid += ', ' unless mid.empty?
            mid += executable_names.map(&:inspect).join(', ')
            "#{start}#{mid}#{end_char}"
            #.tap{|r| puts "#{[start,mid].inspect} ---> #{r.inspect}"}
          end

        # Handle case where it is a word array
        elsif /\n[^\n#]+?\.executables\s*=\s*%w(\S)/ === content
          end_char= PERCENT_SYNTAX_CLOSERS[$1] || $1
          new_content= content.sub /(\n[^\n#]+?\.executables\s*=\s*%w.)(.*?)#{Regexp.quote end_char}/m do
            start,mid = $1,$2
            if /\n(\s*)\S.*\n/ === mid
              # Match previous intending in multiline word array
              indent= $1
              contrib= executable_names.map{|e| indent + e }.join "\n"
              mid.sub! /(\n[^\n]*\z)/m, "\n#{contrib}\\1"
            else
              # Append to single-line word array
              mid += ' ' unless mid.empty?
              mid += executable_names.join(' ')
            end
            "#{start}#{mid}#{end_char}"
            #.tap{|r| puts "#{[start,mid].inspect} ---> #{r.inspect}"}
          end

        # Handle case where it is defined some other way
        elsif gem_var and /\n[^\n#]+?\.executables.*?=/m === content
          new_lines= executable_names.map {|exe|
            exe= exe.inspect
            "#{gem_var}.executables << #{exe} unless #{gem_var}.executables.include? #{exe}"
          }.join "\n"
          new_content= append_to_code_block(new_lines, content, gem_block_closer, gem_block_closer_regex)
        end

        # This code currently makes no effort only add new items. It just adds what it's been told.
        # Thus if new_content doesn't contain any changes, it means something didn't work.
        new_content= nil if new_content == content

        # Save the result or warn the user
        if new_content
          create_file gemspec_file, new_content, force: true
          true
        else
          say_status 'gemspec', "Failed to update gemspec: #{gemspec_file}. Add the following executables to it manually:", :red
          executable_names.each{|n| say "              - #{n}" }
          false
        end
      end

      alias :add_executables_to_gemspec :add_executable_to_gemspec

      private

      # Adds a line (or lines) of code to the end of a block in string of Ruby code.
      #
      # @param [String] new_line A line of text. Add carriage returns for multiple lines; indenting will be taken care
      #   of for you.
      # @param [String] content The code that `new_line` will be inserted into.
      # @param [String] gem_block_closer A string indicating the end of a block. Usually either `end` or `}`.
      # @param [Regexp] gem_block_closer_regex A regexp that selects the end of a block. Make it smarter than just using
      #   `Regexp.quote` by adding look-ahead/look-behind checks.
      # @return [nil|String] `nil` if the end-of-block wasn't found, else a new copy of the code with the new lines
      #   inserted.
      def append_to_code_block(new_line, content, gem_block_closer, gem_block_closer_regex)
        segments= (content + '!').split gem_block_closer_regex
        if segments.size > 1
          s= segments[-2]

          if /\n(\s*?)\S[^\n]*?\n[^\n]*\z/ === s
            indent= $1.sub /\A\n/, ''
            s.sub! /(\n[^\n]*\z)/, "\n#{indent}#{new_line.gsub /(?<=\n)/, indent}\\1"
          else
            s += "\n" + new_line + "\n"
          end
          segments[-2]= s
          segments.join(gem_block_closer)[0..-2]
        else
          nil
        end
      end

      # Map of matching braces Ruby uses for things like %w[], %r<>, etc.
      # @!visibility private
      PERCENT_SYNTAX_CLOSERS= {
        '<' => '>',
        '(' => ')',
        '[' => ']',
        '{' => '}',
      }

      # @!visibility private
      BLOCK_CLOSERS= {
        'do' => {str: 'end', regex: /(?<![a-zA-Z0-9_])end(?![a-zA-Z0-9_])/},
        '{' => {str: '}', regex: /\}/},
      }

      # @!visibility private
      BLOCK_OPENERS_REGEX_STR= "(?:#{BLOCK_CLOSERS.keys.map{|k| Regexp.quote k }.join '|'})"

      #-----------------------------------------------------------------------------------------------------------------

      # @!visibility private
      def self.included(target)
        target.extend ClassMethods
      end

      module ClassMethods

        # @!visibility private
        RUN_BUNDLE= ActionExtensions::RUN_BUNDLE

        # Declares a Thor option that allows users to opt-out of Bundler being run at the end of certain tasks.
        #
        # @param [Base] g The generator in which to delcare the option.
        # @return [void]
        # @see Corvid::Generator::ActionExtensions::RUN_BUNDLE
        # @see #run_bundle_at_exit
        def declare_option_to_run_bundle_at_exit(g)
          g.method_option RUN_BUNDLE, type: :boolean, default: true, optional: true
        end

      end
    end
  end
end
