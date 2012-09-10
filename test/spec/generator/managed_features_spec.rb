# encoding: utf-8
require_relative '../../bootstrap/spec'
require 'corvid/generator/managed_features'

describe Corvid::Generator::ManagedFeatures do
  include described_class

  describe '#create_install_task_for' do
    let(:g){ create_install_task_for('abc:f123').new }

    it("creates a generator"){
      g.should be_kind_of ::Corvid::Generator::Base
    }
    it("lives the namespace <plugin>:install"){
      g.class.namespace.should == 'abc:install'
    }
    it("installs the specified feature"){
      g.should_receive(:install_feature).once.with('abc','f123')
      g.f123
    }
  end
end
