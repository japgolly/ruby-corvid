# encoding: utf-8
require_relative '../../../spec_helper'
require 'corvid/generators/init/corvid'

describe Corvid::Generator::InitCorvid do

  def assert_corvid_version_is_latest
    v= YAML.load_file(CONST::VERSIONS_FILE)
    v.should be_kind_of(Hash)
    v['corvid'].should == Corvid::ResPatchManager.new.latest_version
  end

  context 'in an empty directory' do
    context 'base feature only' do
      run_all_in_empty_dir {
        run_generator described_class, "init --no-test-unit --no-test-spec"
      }
      it("should create Gemfile"){ 'Gemfile'.should exist_as_a_file }
      it("should store the resource version"){ assert_corvid_version_is_latest }
      it("should store the corvid plugin"){ assert_plugins_installed BUILTIN_PLUGIN_DETAILS }
      it("should store the corvid feature"){ assert_features_installed 'corvid:corvid' }
    end
    context 'with additional features' do
      run_all_in_empty_dir {
        run_generator described_class, "init --test-unit --test-spec"
      }
      it("should create Gemfile"){ 'Gemfile'.should exist_as_a_file }
      it("should store the resource version"){ assert_corvid_version_is_latest }
      it("should store the corvid and test features"){ assert_features_installed %w[corvid:corvid corvid:test_unit corvid:test_spec] }
    end
  end

  it("should overwrite the resource version when it exists"){
    inside_empty_dir {
      Dir.mkdir '.corvid'
      File.write CONST::VERSIONS_FILE, {'corvid'=>0}.to_yaml
      run_generator described_class, "init --no-test-unit --no-test-spec"
      assert_corvid_version_is_latest
    }
  }

end
