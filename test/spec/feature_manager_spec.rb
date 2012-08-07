# encoding: utf-8
require_relative '../spec_helper'
require 'corvid/feature_manager'

describe Corvid::FeatureManager do
  subject{ described_class.send :new }

  describe "Getting a feature instance" do
    it("should return nothing when there is no feature class"){
      subject.instance_for('corvid').should be_nil
    }

    it("should fail when feature is unknown"){
      expect{ subject.instance_for('porn!') }.to raise_error
    }

    it("should create a new instance"){
      i= subject.instance_for('plugin')
      i.should_not be_nil
      i.class.to_s.should == 'Corvid::Builtin::PluginFeature'
    }

    it("should reuse a previously-created instance"){
      i= subject.instance_for('plugin')
      i.should_not be_nil
      i2= subject.instance_for('plugin')
      i.object_id.should == i2.object_id
    }
  end

end
