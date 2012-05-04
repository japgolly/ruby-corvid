require 'raven/generators/base'

module Raven::Generator::Init
  class Test < Raven::Generator::Base

    desc 'unit', 'Adds support for unit tests.'
    def unit
      copy_file_unless_exists 'test/bootstrap/all.rb'
      copy_file 'test/bootstrap/unit.rb'
    end

    desc 'spec', 'Adds support for specifications.'
    def spec
      copy_file_unless_exists 'test/bootstrap/all.rb'
      copy_file 'test/bootstrap/spec.rb'
    end

  end
end
