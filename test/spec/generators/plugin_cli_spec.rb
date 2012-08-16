# encoding: utf-8
require_relative '../../spec_helper'
require 'corvid/generators/plugin_cli'
require 'corvid/plugin'

describe Corvid::Generator::PluginCli do

  class FakePlugin < Corvid::Plugin
    name 'fake'
    require_path 'fk/plugin'
    resources_path 'fk/res'
  end

  let(:fake_plugin){ FakePlugin.new }
  let(:subject){
    g= quiet_generator(described_class)
    g.stub plugin: fake_plugin
    #g.plugin_registry= Corvid::PluginRegistry.send(:new)
    #g.plugin_registry.use_plugin fake_plugin
    g.should_not_receive :plugin_registry
    g
  }

  describe '#install' do
    it("installs the specified plugin"){
      subject.should_receive(:add_plugin).with(fake_plugin).once
      subject.install
    }
  end

  describe '#update' do
    it("updates the specified plugin"){
      ug= mock 'update generator'
      ::Corvid::Generator::Update.should_receive(:new).once.and_return(ug)
      ug.should_receive(:update).once.with('fake')
      subject.update
    }
  end
end
