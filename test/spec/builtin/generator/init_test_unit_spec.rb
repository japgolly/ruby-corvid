# encoding: utf-8
require_relative '../../../bootstrap/spec'
require 'corvid/builtin/generator/init_test_unit'
require 'helpers/test_bootstraps'

describe Corvid::Builtin::Generator::InitTestUnit do
  include TestBootstraps

  describe 'init:test:unit' do
    run_each_in_dynamic_fixture :corvid_only

    it("should initalise unit test support"){
      run_generator described_class, "unit"
      test_bootstraps true, true, false
      'test/unit'.should exist_as_dir
      assert_features_installed %w[corvid:corvid corvid:test_unit]
      'Gemfile'.should be_file_with_contents(/gem.*corvid/)
                       .and(/test/)
                       .and(/guard/)
                       .and(/minitest/)
                       .and_not(/rspec/)
                       .and_not(/^[<=>]{6}/)
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
