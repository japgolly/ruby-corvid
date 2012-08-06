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

    end
  end
end
