# encoding: utf-8
require_relative '../../../spec_helper'
require 'corvid/generators/init/test_unit'
require 'helpers/test_bootstraps'

describe Corvid::Generator::InitTestUnit do
  include TestBootstraps

  describe 'init:test:unit' do
    run_each_in_dynamic_fixture :bare

    it("should initalise unit test support"){
      run_generator described_class, "unit"
      test_bootstraps true, true, false
      'test/unit'.should exist_as_dir
      assert_features_installed %w[corvid:corvid corvid:test_unit]
    }

    it("should preserve the common bootstrap"){
      FileUtils.mkdir_p File.dirname(BOOTSTRAP_ALL)
      File.write BOOTSTRAP_ALL, '123'
      run_generator described_class, "unit"
      File.read(BOOTSTRAP_ALL).should == '123'
      test_bootstraps nil, true, false
      Dir.exists?('test/unit').should == true
    }

  end
end
