# encoding: utf-8
require_relative '../spec_helper'
require 'corvid/extension_registry'

describe Corvid::ExtensionRegistry do
  subject{ described_class.send :new }

  class MockExtension
    include Corvid::Extension
  end

  it("should load all installed features"){
    fm= mock 'FeatureManager'
    pf= MockExtension.new
    fm.should_receive(:instances_for_installed).once.and_return 'corvid'=>nil, 'plugin'=>pf
    subject.feature_manager= fm
    subject.extensions.should == [pf]
  }

  it("should run all extensions for a given extension point"){
    e= mock 'Extension'
    e.should_receive(:run_callback).with(:hello).once
    subject.stub extensions: [e]
    subject.run_extensions_for :hello
  }
end
