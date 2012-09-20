# encoding: utf-8
require_relative '../../../bootstrap/spec'
require 'corvid/builtin/generator/init_corvid'

describe Corvid::Builtin::Generator::InitCorvid do

  def assert_corvid_version_is_latest
    v= YAML.load_file(CONST::VERSIONS_FILE)
    v.should be_kind_of(Hash)
    v['corvid'].should == Corvid::ResPatchManager.new.latest_version
  end

  shared_examples 'corvid' do
    it("should create Gemfile"){
      'Gemfile'.should exist_as_a_file
    }

    it("should not have any merge conflicts in Gemfile"){
      'Gemfile'.should_not be_file_with_contents /^[<=>]{6}/
    }

    it("should store the resource version"){
      assert_corvid_version_is_latest
    }

    it("should create a version file"){
      'lib/my_thing/version.rb'.should be_file_with_contents(%r|module MyThing\n|).and(%r|VERSION = |)
    }

    it("should create a gemspec"){
      'my_thing.gemspec'.should be_file_with_contents(%r|lib/my_thing/version|)
        .and(%r|gem\.name.+"my_thing"|)
        .and(%r|gem\.version.+MyThing::VERSION|)
    }
  end

  context 'in an empty directory' do
    context 'base feature only' do
      run_all_in_dynamic_fixture :corvid_only
      include_examples 'corvid'
      it("should store the corvid plugin"){ assert_plugins_installed BUILTIN_PLUGIN_DETAILS }
      it("should store the corvid feature"){ assert_features_installed 'corvid:corvid' }
      it("should not contain any test dependencies"){
        'Gemfile'.should be_file_with_contents(/gem.*corvid/).and_not(/test/).and_not(/guard/).and_not(/rspec/)
      }
    end

    context 'with additional features' do
      run_all_in_empty_dir("my_thing") {
        run_generator described_class, "init --test-unit --test-spec"
      }

      include_examples 'corvid'
      it("should store the corvid and test features"){ assert_features_installed %w[corvid:corvid corvid:test_unit corvid:test_spec] }
      it("should contain test dependencies"){
        'Gemfile'.should be_file_with_contents(/gem.*corvid/).and(/test/).and(/guard/).and(/rspec/)
      }
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
