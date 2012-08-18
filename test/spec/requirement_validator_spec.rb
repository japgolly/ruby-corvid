# encoding: utf-8
require_relative '../spec_helper'
require 'corvid/requirement_validator'

describe Corvid::RequirementValidator do

  describe '#add' do
    def test(arg, result)
      subject.add arg
      subject.requirements.sort_by(&:to_s).should equal_array result.sort_by(&:to_s)
    end

    it("interprets strings with no colon as plugin names"){
      test 'a', [{plugin:'a'}]
    }

    it("interprets strings with colons as feature names"){
      test 'ba:hehe', [{plugin:'ba',feature_id:'ba:hehe'}]
    }

    it("preserve existing requirements when adding"){
      test 'what', [{plugin:'what'}]
      test 'what2', [{plugin:'what'},{plugin:'what2'}]
    }

    it("ignores duplicates"){
      test 'what', [{plugin:'what'}]
      test 'what', [{plugin:'what'}]
    }

    it("ignores nils"){
      test nil, []
      test [nil,nil], []
    }

    it("fails if plugin name is invalid"){
      expect{ subject.add 'what is this' }.to raise_error /plugin/
    }

    it("fails if feature id is invalid"){
      expect{ subject.add 'what:is:this' }.to raise_error /feature/
    }

    it("accepts an array"){
      test %w[a b c], [{plugin:'a'}, {plugin:'b'}, {plugin:'c'}]
    }

    it("accepts a hash and interprets values as version requirements"){
      test( {'a' => 3, 'b' => 2..5}, [{plugin:'a',version:3}, {plugin:'b',version:2..5}] )
    }

    it("allows multiple requirements for the same target"){
      subject.add 'p'
      subject.add({'p'=>2})
      subject.add({'p'=>5..8})
      subject.add 'p'
      subject.requirements.should include({plugin:'p',version:5..8})
    }

  end

  describe '#clear' do
    it("removes all registered requirements"){
      subject.add 'ha'
      subject.clear
      subject.requirements.should be_empty
    }
  end

  describe '#check' do
    it("validates plugin installed"){
      subject.set_client_state %w[p], nil, nil
      subject.check(plugin:'p').should be_nil
      subject.check(plugin:'a').should be_a String
    }

    it("validates feature installed"){
      subject.set_client_state %w[p], %w[p:a], nil
      subject.check(plugin:'p',feature_id:'p:a').should be_nil
      subject.check(plugin:'p',feature_id:'p:b').should be_a String
    }

    it("validates minimum resources version"){
      subject.set_client_state %w[p], nil, {'p'=>3}
      subject.check(plugin:'p', version:1).should be_nil
      subject.check(plugin:'p', version:3).should be_nil
      subject.check(plugin:'p', version:4).should be_a String
    }

    it("validates version range"){
      subject.set_client_state %w[p], nil, {'p'=>3}
      subject.check(plugin:'p', version:1..7).should be_nil
      subject.check(plugin:'p', version:1..3).should be_nil
      subject.check(plugin:'p', version:3..3).should be_nil
      subject.check(plugin:'p', version:3..4).should be_nil
      subject.check(plugin:'p', version:2..2).should be_a String
      subject.check(plugin:'p', version:4..8).should be_a String
    }

    it("validates version list"){
      subject.set_client_state %w[p], nil, {'p'=>3}
      subject.check(plugin:'p', version:[2,3]).should be_nil
      subject.check(plugin:'p', version:[2,4]).should be_a String
    }
  end


  describe 'validation' do
    shared_examples 'validation successful' do
      it("#validate returns true"){ subject.validate.should be_true }
      it("#errors returns an empty array"){ subject.errors.should == [] }
      it("#validate! returns self"){ subject.validate!().should == subject }
    end

    context "when there are no requirements" do
      before(:each){
        subject.set_client_state %w[p1], nil, nil
      }
      include_examples 'validation successful'
    end

    context "when all requirements are satisfied" do
      before(:each){
        subject.set_client_state %w[p1], nil, nil
        subject.add 'p1'
      }
      include_examples 'validation successful'
    end

    context "when requirements are not satisfied" do
      before(:each){
        subject.set_client_state %w[p1], nil, nil
        subject.add 'p2', 'p3'
      }
      it("#validate returns false"){ subject.validate.should be_false }
      it("#errors returns an array of unsatisfied requirements and error messages"){ subject.errors.size.should == 2 }
      it("#validate! raises an exception"){ expect{ subject.validate! }.to raise_error }
    end
  end
end
