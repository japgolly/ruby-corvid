# encoding: utf-8
require_relative '../../../spec_helper'
require 'corvid/generators/new/unit_test'

describe Corvid::Generator::NewUnitTest do
  run_each_in_dynamic_fixture :bare
  before(:each){ add_feature! 'corvid:test_unit' }

  describe 'new:test:unit' do
    it("simplest case"){
      run_generator described_class, 'unit hehe'
      'test/unit/hehe_test.rb'.should be_file_with_contents <<-EOB
# encoding: utf-8
require_relative '../bootstrap/unit'
require 'hehe'

class HeheTest < MiniTest::Unit::TestCase
  # T\ODO
end
      EOB
    }

    it("with leading slash, subdir, module and file ext"){
      run_generator described_class, 'unit /what/say::good.rb'
      'test/unit/what/say/good_test.rb'.should be_file_with_contents <<-EOB
# encoding: utf-8
require_relative '../../../bootstrap/unit'
require 'what/say/good'

class GoodTest < MiniTest::Unit::TestCase
  # T\ODO
end
      EOB
    }
  end
end
