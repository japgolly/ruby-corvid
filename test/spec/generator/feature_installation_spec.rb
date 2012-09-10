# encoding: utf-8
require_relative '../../bootstrap/spec'
require 'corvid/generator/init/corvid'
require 'corvid/generator/init/test_unit'
require 'corvid/res_patch_manager'
require 'helpers/fixture-upgrading'

describe 'Feature Installation', :slow do
  include Fixtures::Upgrading

  run_all_in_empty_dir {
    prepare_res_patches
    prepare_base_dirs do |ver|
      run_generator Corvid::Generator::InitCorvid, "init --no-test-unit --no-test-spec"
      'Gemfile'.should_not exist_as_a_file # Make sure it's not using real res-patches
      assert_installation ver, 0
    end
  }

  def run_init_test_unit_task
    run_generator Corvid::Generator::InitTestUnit, 'unit'
  end

  def self.test_feature_installation(max_version_available)
    1.upto(max_version_available) do |inst_ver|
      eval <<-EOB
        context 'installation of a feature on top of v#{inst_ver}' do
          run_all_in_sandbox_copy_of(#{inst_ver}) do
            run_init_test_unit_task
            @features= Corvid::FeatureRegistry.send(:new).read_client_features
          end

          it("should install v#{inst_ver} of the feature"){
            assert_installation #{inst_ver}, #{inst_ver}
          }
          it("should preserve the existing features in the registry"){
            @features.should include('corvid:corvid')
          }
          it("should register the new feature"){
            @features.should include('corvid:test_unit')
          }
        end
      EOB
    end
  end

  context 'when latest version available is v1' do
    run_all_with_corvid_resources_version 1
    test_feature_installation 1
  end

  context 'when latest version available is v2' do
    run_all_with_corvid_resources_version 2
    test_feature_installation 2

    it("should do nothing if feature already installed"){
      with_sandbox_copy_of(2) do
        add_feature! 'corvid:test_unit'
        run_init_test_unit_task
        assert_installation 2, 0
      end
    }
  end

  context 'when latest version available is v3' do
    run_all_with_corvid_resources_version 3
    test_feature_installation 3
  end

  context 'when latest version available is v4' do
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
