require 'corvid/generators/base'

class Corvid::Generator::Init < Corvid::Generator::Base

  desc 'project', 'Creates a new Corvid project in the current directory.'
  method_option :'test-unit', type: :boolean
  method_option :'test-spec', type: :boolean
  def project
    copy_file '.gitignore'
    copy_file '.simplecov'
    copy_file 'Gemfile'
    empty_directory 'lib'
    invoke 'init:test:unit', nil, :'update-deps' => false if boolean_specified_or_ask :'test-unit', 'Add support for unit tests?'
    invoke 'init:test:spec', nil, :'update-deps' => false if boolean_specified_or_ask :'test-spec', 'Add support for specs?'
    invoke 'update:deps'
  end

  class Test < Corvid::Generator::Base

    desc 'unit', 'Adds support for unit tests.'
    method_options :'update-deps' => true
    def unit
      copy_file_unless_exists 'test/bootstrap/all.rb'
      copy_file 'test/bootstrap/unit.rb'
      empty_directory 'test/unit'
      invoke 'update:deps' if options[:'update-deps']
    end

    desc 'spec', 'Adds support for specifications.'
    method_options :'update-deps' => true
    def spec
      copy_file_unless_exists 'test/bootstrap/all.rb'
      copy_file 'test/bootstrap/spec.rb'
      empty_directory 'test/spec'
      invoke 'update:deps' if options[:'update-deps']
    end

  end
end
