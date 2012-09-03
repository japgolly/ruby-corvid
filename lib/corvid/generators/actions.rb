module Corvid
  module Generator

    # Provides additional actions, and extentions to Thor actions.
    module ActionExtentions

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
      # @param [String] file The filename of the template. Normally ends in `.tt`.
      # @param [Hash,String,Symbol,Array<String|Symbol>] args If a Hash is provided then it is a map of template
      #   variable names to values. If anything else then (String, array of symbols) it is assumed to be one or more
      #   variable names with instance methods that can be called to provide the value.
      # @option args [Fixnum] :perms (nil) If provided, the new file will be chmod'd with the given permissions here.
      # @return [void]
      def template2(file, args)
        src= file
        target= file.sub /\.tt$/, ''
        unless args.is_a?(Hash)
          names= [args].flatten
          args= names.inject({}){|h,name| h[name]= send name.to_sym; h}
        end

        perms= args.delete :perms
        args.each do |k,v|
          target.gsub! "%#{k}%", v
        end

        template src, target
        chmod target, perms if perms
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

        ge= GemfileEvaluator.new.eval_string(content)
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

      private

      # Used to parse Gemfile content and provide list of declared gems.
      #
      # @!visibility private
      # @see #add_dependencies_to_gemfile
      class GemfileEvaluator
        attr_reader :gems

        def initialize
          @gems= {}
        end

        def eval_string(content)
          instance_eval content
          self
        end

        def group(group_name, *args)
          return unless block_given?
          prev_group_name= @group_name
          begin
            @group_name= group_name
            yield
          ensure
            @group_name= prev_group_name
          end
          nil
        end

        def gem(gem_name, *args)
          if @group_name
            args= args.dup
            args<< {} unless args.last.is_a?(Hash)
            args.last[:group] ||= @group_name
          end
          @gems[gem_name]= args
          nil
        end

        def method_missing(method, *args, &block)
          instance_eval &block if block
          nil
        end
      end

    end
  end
end
