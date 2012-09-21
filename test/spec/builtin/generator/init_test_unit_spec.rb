# encoding: utf-8
require_relative '../../../bootstrap/spec'
require 'corvid/builtin/generator/init_test_unit'
require 'helpers/test_bootstraps'
require 'golly-utils/testing/dynamic_fixtures'
require 'golly-utils/testing/rspec/files'

describe Corvid::Builtin::Generator::InitTestUnit do
  include TestBootstraps

  context 'when test_spec not installed' do
    run_all_in_dynamic_fixture(:corvid_only){
      '.simplecov'.should_not exist_as_file
      'Guardfile'.should_not exist_as_file
      run_generator described_class, "unit"
    }
    it("installs the test_unit feature"){ assert_features_installed %w[corvid:corvid corvid:test_unit] }
    it("creates bootstraps"){ test_bootstraps true, true, false }
    it("creates a test/unit dir"){ 'test/unit'.should exist_as_dir }
    it("deploys simplecov settings"){ '.simplecov'.should exist_as_file }
    it("adds test dependencies"){
      'Gemfile'.should be_file_with_contents(/gem.*corvid/)
        .and(/test/)
        .and(/guard/)
        .and(/minitest/)
        .and_not(/rspec/)
        .and_not(/^[<=>]{6}/)
    }
    it("creates a Guardfile configured for unit tests"){
      'Guardfile'.should be_file_with_contents(%r'corvid/builtin/guard')
        .and(%r'test/unit')
        .and(%r'minitest')
        .and_not(%r'test/spec')
        .and_not(%r'rspec')
    }
  end

  context 'when test_spec is installed' do
    run_all_in_dynamic_fixture(:corvid_then_test_spec){
      '.simplecov'.should exist_as_file
      'Guardfile'.should be_file_with_content(/rspec/).and_not(/minitest/)
      File.write '.simplecov', 'custom'
      run_generator described_class, "unit"
    }
    it("installs the test_unit feature"){ assert_features_installed %w[corvid:corvid corvid:test_spec corvid:test_unit] }
    it("creates bootstraps"){ test_bootstraps true, true, true }
    it("creates a test/unit dir"){ 'test/unit'.should exist_as_dir }
    it("preserve simplecov settings"){ '.simplecov'.should be_file_with_content 'custom' }
    it("adds test dependencies"){
      'Gemfile'.should be_file_with_contents(/gem.*corvid/)
        .and(/test/)
        .and(/guard/)
        .and(/minitest/)
        .and(/rspec/)
        .and_not(/^[<=>]{6}/)
    }
    it("adds unit test dependencies to Guardfile"){
      'Guardfile'.should be_file_with_contents(%r'corvid/builtin/guard')
        .and(%r'test/unit')
        .and(%r'minitest')
        .and(%r'test/spec')
        .and(%r'rspec')
    }
  end

  it("should preserve the common bootstrap"){
    inside_dynamic_fixture :corvid_only do
      FileUtils.mkdir_p File.dirname(BOOTSTRAP_ALL)
      File.write BOOTSTRAP_ALL, '123'
      run_generator described_class, "unit"
      File.read(BOOTSTRAP_ALL).should == '123'
      test_bootstraps nil, true, false
      'test/unit'.should exist_as_dir
    end
  }
end
