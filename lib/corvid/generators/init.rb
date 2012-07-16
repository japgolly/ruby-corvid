require 'corvid/generators/base'

class Corvid::Generator::Init < Corvid::Generator::Base

  desc 'project', 'Creates a new Corvid project in the current directory.'
  method_option :'test-unit', type: :boolean
  method_option :'test-spec', type: :boolean
  run_bundle_option(self)
  def project
    empty_directory '.corvid'
    copy_file       '.corvid/Gemfile'
    copy_file       '.gitignore'
    copy_file       '.simplecov'
    copy_file       '.yardopts'
    copy_file       'CHANGELOG.md'
    copy_file       'Gemfile'
    copy_file       'Guardfile'
    copy_file       'Rakefile'
    copy_file       'README.md'
    copy_executable 'bin/rake'
    copy_executable 'bin/yard'
    copy_executable 'bin/yardoc'
    copy_executable 'bin/yri'
    empty_directory 'lib'

    invoke 'init:test:unit', [], RUN_BUNDLE => false if boolean_specified_or_ask :'test-unit', 'Add support for unit tests?'
    invoke 'init:test:spec', [], RUN_BUNDLE => false if boolean_specified_or_ask :'test-spec', 'Add support for specs?'
    run_bundle
  end

  class Test < Corvid::Generator::Base

    desc 'unit', 'Adds support for unit tests.'
    run_bundle_option(self)
    def unit
      copy_executable         'bin/guard'
      copy_file_unless_exists 'test/bootstrap/all.rb'
      copy_file               'test/bootstrap/unit.rb'
      empty_directory         'test/unit'
      run_bundle
    end

    desc 'spec', 'Adds support for specifications.'
    run_bundle_option(self)
    def spec
      copy_file               '.rspec'
      copy_executable         'bin/guard'
      copy_executable         'bin/rspec'
      copy_file_unless_exists 'test/bootstrap/all.rb'
      copy_file               'test/bootstrap/spec.rb'
      empty_directory         'test/spec'
      run_bundle
    end

  end
end
