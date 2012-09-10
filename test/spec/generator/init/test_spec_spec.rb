# encoding: utf-8
require_relative '../../../bootstrap/spec'
require 'corvid/generator/init/test_spec'
require 'helpers/test_bootstraps'

describe Corvid::Generator::InitTestSpec do
  include TestBootstraps

  describe 'init:test:spec' do
    run_each_in_dynamic_fixture :bare

    it("should initalise spec test support"){
      run_generator described_class, "spec"
      test_bootstraps true, false, true
      'test/spec'.should exist_as_dir
      assert_features_installed %w[corvid:corvid corvid:test_spec]
    }

    it("should preserve the common bootstrap"){
      FileUtils.mkdir_p File.dirname(BOOTSTRAP_ALL)
      File.write BOOTSTRAP_ALL, '123'
      run_generator described_class, "spec"
      File.read(BOOTSTRAP_ALL).should == '123'
      test_bootstraps nil, false, true
      Dir.exists?('test/spec').should == true
    }

  end
end
