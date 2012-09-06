# encoding: utf-8
require_relative '../spec_helper'
require 'corvid/feature_registry'
require 'corvid/feature'

describe Corvid::FeatureRegistry do
  subject{ described_class.send :new }

  before :each do
    subject.plugin_registry= mock 'plugin_registry'
    subject.plugin_registry.stub instances_for_installed: {'corvid' => BUILTIN_PLUGIN.new}
    subject.plugin_registry.stub validate_plugin_name!: true
  end

  describe "#instance_for" do
    it("should return nothing when there is no feature class"){
      subject.stub feature_manifest: {'corvid:corvid'=>nil}
      subject.instance_for('corvid:corvid').should be_nil
    }

    it("should fail when feature is unknown"){
      expect{ subject.instance_for('corvid:crazy') }.to raise_error
    }

    it("should create a new instance"){
      i= subject.instance_for('corvid:corvid')
      i.should_not be_nil
      i.class.to_s.should == 'Corvid::Builtin::CorvidFeature'
    }

    it("should reuse a previously-created instance"){
      i= subject.instance_for('corvid:corvid')
      i.should_not be_nil
      i2= subject.instance_for('corvid:corvid')
      i.object_id.should == i2.object_id
    }

    class FakeFeature < ::Corvid::Feature; end
    it("should read plugins' feature manifests"){
      p= stub name: 'blah', feature_manifest: {'crazy' => [nil,FakeFeature.to_s]}
      subject.plugin_registry.stub instances_for_installed: {'blah' => p}
      i= subject.instance_for('blah:crazy')
      i.should_not be_nil
      i.should be_a FakeFeature
    }

    it("should fail if feature name isn't prefixed by plugin"){
      %w[corvid corvid: :corvid :corvid: corvid:corvid: corvid:corvid:asd].each do |name|
        expect{ subject.instance_for name }.to raise_error %r[#{name}]
      end
    }
  end

  describe "#instances_for_installed" do
    before :each do
      subject.stub read_client_features: %w[corvid:corvid corvid:test_unit]
      subject.stub(feature_manifest: {
        'corvid:corvid'    => ['corvid/builtin/corvid_feature','Corvid::Builtin::CorvidFeature'],
        'corvid:test_unit' => nil,
      })
    end

    it("should return a key for each installed feature"){
      f= subject.instances_for_installed
      f.should be_a Hash
      f.keys.should equal_array %w[corvid:corvid corvid:test_unit]
    }

    it("should return instances for installed features"){
      pf= subject.instances_for_installed()['corvid:corvid']
      pf.should_not be_nil
      pf.class.to_s.should == 'Corvid::Builtin::CorvidFeature'
    }

    it("should return nil for installed features without Feature classes"){
      subject.instances_for_installed()['corvid:test_unit'].should be_nil
    }
  end

  describe '#feature_manifest' do
    it("should prefix feature names with plugin name"){
      p1= stub name: 'p1', feature_manifest: {'happy'=>[nil,'Happy'], 'tired'=>['tired','Tired']}
      p2= stub name: 'p2', feature_manifest: {'eat'=>[nil,'Eat']}
      subject.plugin_registry.stub instances_for_installed: {'p1'=>p1, 'p2'=>p2}
      subject.feature_manifest.keys.should equal_array %w[p1:happy p1:tired p2:eat]
    }

    it("should fail if a plugin name contains a colon"){
      p2= stub feature_manifest: {'eat'=>[nil,'Eat']}
      expect{
        subject.plugin_registry.stub instances_for_installed: {'p2:no'=>p2}
        subject.feature_manifest
      }.to raise_error
    }

    it("should fail if a feature name contains a colon"){
      p2= stub name: 'p2', feature_manifest: {'eat:no'=>[nil,'Eat']}
      expect{
        subject.plugin_registry.stub instances_for_installed: {'p2'=>p2}
        subject.feature_manifest
      }.to raise_error /eat:no/
    }

  end
end
