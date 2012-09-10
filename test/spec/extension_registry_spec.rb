# encoding: utf-8
require_relative '../bootstrap/spec'
require 'corvid/extension_registry'

describe Corvid::ExtensionRegistry do
  subject{ described_class.send :new }

  class MockExtension
    include Corvid::Extension
  end

  before :each do
    subject.feature_registry= mock 'FeatureRegistry'
    subject.plugin_registry= mock 'PluginRegistry'
  end

  it("should load all installed features"){
    ext= MockExtension.new
    subject.feature_registry.should_receive(:instances_for_installed).once.and_return 'corvid'=>nil, 'plugin'=>ext
    subject.plugin_registry.stub instances_for_installed: {}
    subject.extensions.should == [ext]
  }

  it("should load all installed plugins"){
    ext= MockExtension.new
    subject.feature_registry.stub instances_for_installed: {}
    subject.plugin_registry.should_receive(:instances_for_installed).once.and_return 'corvid'=>Object.new, 'plugin'=>ext
    subject.extensions.should == [ext]
  }

  it("should run all extensions for a given extension point"){
    e= mock 'Extension'
    e.should_receive(:run_callback).with(:hello).once
    subject.stub extensions: [e]
    subject.run_extensions_for :hello
  }
end
