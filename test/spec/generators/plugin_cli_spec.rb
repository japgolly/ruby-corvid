# encoding: utf-8
require_relative '../../bootstrap/spec'
require 'corvid/generators/plugin_cli'
require 'corvid/plugin'

describe Corvid::Generator::PluginCli do
  add_generator_lets

  class FakePlugin < Corvid::Plugin
    name 'fake'
    require_path 'fk/plugin'
    resources_path 'fk/res'
  end

  let(:fake_plugin){ FakePlugin.new }
  let(:g){
    subject.plugin= fake_plugin
    subject.stub :add_plugin
    subject
  }

  describe '#install' do
    it("installs the specified plugin"){
      g.should_receive(:add_plugin).with(fake_plugin).once
      g.install
    }
    it("validates plugin requirements"){
      fake_plugin.should_receive(:requirements)
      rv= mock_new ::Corvid::RequirementValidator, true
      rv.should_receive(:validate!)
      g.install
    }
  end

  describe '#update' do
    it("updates the specified plugin"){
      ug= mock_new ::Corvid::Generator::Update, false
      ug.should_receive(:update).once.with('fake')
      g.update
    }
  end
end
