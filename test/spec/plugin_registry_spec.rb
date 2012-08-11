# encoding: utf-8
require_relative '../spec_helper'
require 'corvid/plugin_registry'

describe Corvid::PluginRegistry do
  subject{ described_class.send :new }

  class FakePlugin < ::Corvid::Plugin
  end

  def mock_plugins_file(contents)
    File.stub exists?: true
    YAML.should_receive(:load_file).once.and_return(contents)
  end

  before :each do
    mock_plugins_file BUILTIN_PLUGIN_DETAILS.merge('fake' => {class:FakePlugin.to_s})
  end

  describe "#instance_for" do
    it("should fail when plugin is unknown"){
      expect{ subject.instance_for('porn!') }.to raise_error
    }

    it("should create a new instance"){
      i= subject.instance_for('corvid')
      i.should_not be_nil
      i.should be_a BUILTIN_PLUGIN
    }

    it("should reuse a previously-created instance"){
      i= subject.instance_for('corvid')
      i.should_not be_nil
      i2= subject.instance_for('corvid')
      i.object_id.should == i2.object_id
    }
  end

  describe "#instances_for_installed" do
    it("should return a key for each plugin"){
      f= subject.instances_for_installed
      f.should be_a Hash
      f.keys.should equal_array %w[corvid fake]
    }

    it("should return instances for installed plugins"){
      pf= subject.instances_for_installed()['corvid']
      pf.should_not be_nil
      pf.should be_a BUILTIN_PLUGIN
    }
  end
end
