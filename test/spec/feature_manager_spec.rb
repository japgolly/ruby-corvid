# encoding: utf-8
require_relative '../spec_helper'
require 'corvid/feature_manager'

describe Corvid::FeatureManager do
  subject{ described_class.send :new }

  describe "#instance_for" do
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

  describe "#instances_for_installed" do
    before :each do
      subject.stub read_client_features: %w[corvid test_unit plugin]
    end

    it("should return a key for each installed feature"){
      f= subject.instances_for_installed
      f.should be_a Hash
      f.keys.should equal_array %w[corvid test_unit plugin]
    }

    it("should return instances for installed features"){
      pf= subject.instances_for_installed()['plugin']
      pf.should_not be_nil
      pf.class.to_s.should == 'Corvid::Builtin::PluginFeature'
    }

    it("should return nil for installed features without Feature classes"){
      subject.instances_for_installed()['test_unit'].should be_nil
    }
  end
end
