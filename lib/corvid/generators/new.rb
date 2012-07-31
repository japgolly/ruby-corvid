require 'corvid/generators/base'

module ::Corvid::Generator::New
  class Test < ::Corvid::Generator::Base
    argument :name, type: :string

    desc 'unit', 'Generates a new unit test.'
    def unit
      with_latest_resources do
        template 'test/unit/%src%_test.rb.tt', "test/unit/#{src}_test.rb"
      end
    end

    desc 'spec', 'Generates a new specification.'
    def spec
      with_latest_resources do
        template 'test/spec/%src%_spec.rb.tt', "test/spec/#{src}_spec.rb"
      end
    end

    private

    def src
      name.underscore.gsub /^[\\\/]+|\.rb$/, ''
    end

    def bootstrap_dir
      '../'*src.split(/[\\\/]+/).size + 'bootstrap'
    end

    def testcase_name
      src.split(/[\\\/]+/).last.camelcase
    end

    def subject
      src.camelcase
    end

  end
end
