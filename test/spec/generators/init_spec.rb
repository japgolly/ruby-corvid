# encoding: utf-8
require_relative '../spec_helper'
require 'corvid/generators/init'
require 'corvid/res_patch_manager'
require 'helpers/fixture-upgrading'
require 'yaml'

describe Corvid::Generator::Init do
  context 'init:project' do

    def assert_corvid_version_is_latest
      v= YAML.load_file('.corvid/version.yml')
      v.should be_kind_of(Fixnum)
      v.should == Corvid::ResPatchManager.new.latest_version
    end

    context 'in an empty directory' do
      context 'base feature only' do
        run_all_in_empty_dir {
          run_generator described_class, "project --no-test-unit --no-test-spec"
        }
        it("should create Gemfile"){ 'Gemfile'.should exist_as_a_file }
        it("should store the resource version"){ assert_corvid_version_is_latest }
        it("should store the corvid feature"){ assert_corvid_features 'corvid' }
      end
      context 'with additional features' do
        run_all_in_empty_dir {
          run_generator described_class, "project --test-unit --test-spec"
        }
        it("should create Gemfile"){ 'Gemfile'.should exist_as_a_file }
        it("should store the resource version"){ assert_corvid_version_is_latest }
        it("should store the corvid and test features"){ assert_corvid_features %w[corvid test_unit test_spec] }
      end
    end

    it("should overwrite the resource version when it exists"){
      inside_empty_dir {
        Dir.mkdir '.corvid'
        File.write '.corvid/version.yml', '0'
        run_generator described_class, "project --no-test-unit --no-test-spec"
        assert_corvid_version_is_latest
      }
    }

  end
end

#-----------------------------------------------------------------------------------------------------------------------

describe Corvid::Generator::Init::Test do
  around :each do |ex|
    inside_fixture('bare'){ ex.run }
  end

  context 'init:test:unit' do
    it("should initalise unit test support"){
      run_generator described_class, "unit"
      test_bootstraps true, true, false
      Dir.exists?('test/unit').should == true
      assert_corvid_features %w[corvid test_unit]
    }

    it("should preserve the common bootstrap"){
      FileUtils.mkdir_p File.dirname(BOOTSTRAP_ALL)
      File.write BOOTSTRAP_ALL, '123'
      run_generator described_class, "unit"
      File.read(BOOTSTRAP_ALL).should == '123'
      test_bootstraps nil, true, false
      Dir.exists?('test/unit').should == true
    }
  end # init:test:unit

  context 'init:test:spec' do
    it("should initalise spec test support"){
      run_generator described_class, "spec"
      test_bootstraps true, false, true
      Dir.exists?('test/spec').should == true
      assert_corvid_features %w[corvid test_spec]
    }

    it("should preserve the common bootstrap"){
      FileUtils.mkdir_p File.dirname(BOOTSTRAP_ALL)
      File.write BOOTSTRAP_ALL, '123'
      run_generator described_class, "spec"
      File.read(BOOTSTRAP_ALL).should == '123'
      test_bootstraps nil, false, true
      Dir.exists?('test/spec').should == true
    }
  end # init:test:spec

  def test_bootstraps(all, unit, spec)
    test_bootstrap BOOTSTRAP_ALL,  all,  true,  false, false unless all.nil?
    test_bootstrap BOOTSTRAP_UNIT, unit, false, true,  false unless unit.nil?
    test_bootstrap BOOTSTRAP_SPEC, spec, false, false, true  unless spec.nil?
  end

  def test_bootstrap(file, expected, all, unit, spec)
    if expected
      file.should exist_as_a_file
      c= File.read(file)
      c.send all  ? :should : :should_not, include('corvid/test/bootstrap/all')
      c.send unit ? :should : :should_not, include('unit')
      c.send spec ? :should : :should_not, include('spec')
    else
      file.should_not exist_as_a_file
    end
  end
end

#-----------------------------------------------------------------------------------------------------------------------

describe 'Installing features' do
  include Fixtures::Upgrading

  run_all_in_empty_dir {
    prepare_res_patches
    prepare_base_dirs do |ver|
      run_generator Corvid::Generator::Init, "project --no-test-unit --no-test-spec"
      'Gemfile'.should_not exist_as_a_file # Make sure it's not using real res-patches
      assert_installation ver, 0
    end
  }

  def run_init_test_unit_task
    run_generator Corvid::Generator::Init::Test, 'unit'
  end

  def self.test_feature_installation(max_version_available)
    1.upto(max_version_available) do |inst_ver|
      eval <<-EOB
        context 'feature installed on top of v#{inst_ver}' do
          run_all_in_sandbox_copy_of(#{inst_ver}) do
            run_init_test_unit_task
            @features= Corvid::Generator::Base.new.get_installed_features
          end

          it("should install v#{inst_ver} of the feature"){
            assert_installation #{inst_ver}, #{inst_ver}
          }
          it("should preserve the existing features in the registry"){
            @features.should include('corvid')
          }
          it("should register the new feature"){
            @features.should include('test_unit')
          }
        end
      EOB
    end
  end

  context 'latest version available in corvid is 1' do
    run_all_with_corvid_resources_version 1
    test_feature_installation 1
  end

  context 'latest version available in corvid is 2' do
    run_all_with_corvid_resources_version 2
    test_feature_installation 2

    it("should do nothing if feature already installed"){
      with_sandbox_copy_of(2) do
        f= YAML.load_file('.corvid/features.yml') + ['test_unit']
        File.write '.corvid/features.yml', f.to_yaml
        run_init_test_unit_task
        assert_installation 2, 0
      end
    }
  end

  context 'latest version available in corvid is 3' do
    run_all_with_corvid_resources_version 3
    test_feature_installation 3
  end

  context 'latest version available in corvid is 4' do
    run_all_with_corvid_resources_version 4
    test_feature_installation 4
  end

  context 'Corvid not installed' do
    run_each_in_empty_dir

    it("should refuse feature installation"){
      expect { run_init_test_unit_task }.to raise_error
      get_files().should be_empty
    }
  end
end
