# encoding: utf-8
require_relative '../spec_helper'

describe 'corvid new' do

  around :each do |ex|
    inside_fixture('bare'){ ex.run }
  end

  context 'new:test:unit' do
    it("simplest case"){
      invoke_corvid 'new:test:unit hehe'
      File.read('test/unit/hehe_test.rb').should == <<-EOB
# encoding: utf-8
require_relative '../bootstrap/unit'
require 'hehe'

class HeheTest < MiniTest::Unit::TestCase
  # TODO
end
      EOB
    }

    it("with leading slash, subdir, module and file ext"){
      invoke_corvid 'new:test:unit /what/say::good.rb'
      File.read('test/unit/what/say/good_test.rb').should == <<-EOB
# encoding: utf-8
require_relative '../../../bootstrap/unit'
require 'what/say/good'

class GoodTest < MiniTest::Unit::TestCase
  # TODO
end
      EOB
    }
  end # new:test:unit

  context 'new:test:spec' do
    it("simplest case"){
      invoke_corvid 'new:test:spec hehe'
      File.read('test/spec/hehe_spec.rb').should == <<-EOB
# encoding: utf-8
require_relative '../bootstrap/spec'
require 'hehe'

describe Hehe do
  # TODO
end
      EOB
    }

    it("with leading slash, subdir, module and file ext"){
      invoke_corvid 'new:test:spec /what/say::good.rb'
      File.read('test/spec/what/say/good_spec.rb').should == <<-EOB
# encoding: utf-8
require_relative '../../../bootstrap/spec'
require 'what/say/good'

describe What::Say::Good do
  # TODO
end
      EOB
    }
  end # new:test:spec

end
