# encoding: utf-8
require_relative '../../../bootstrap/spec'
require 'corvid/builtin/generator/init_plugin'

describe Corvid::Builtin::Generator::InitPlugin do
  describe 'init:plugin' do
    run_each_in_empty_dir_unless_in_one_already

    def run!; run_generator described_class, 'plugin' end

    it("should fail if corvid isn't installed yet"){
      expect{ run! }.to raise_error
    }

    it("should fail if corvid:corvid isn't installed yet"){
      copy_dynamic_fixture :bare
      File.delete CONST::FEATURES_FILE
      expect{ run! }.to raise_error Corvid::RequirementValidator::UnsatisfiedRequirementsError
    }

    it("should do nothing if already installed"){
      copy_dynamic_fixture :bare
      add_feature! 'corvid:plugin'
      expect{ run! }.not_to change{ get_dir_entries }
    }

    context 'when installed the first time in a corvid project' do
      run_all_in_empty_dir {
        copy_dynamic_fixture :corvid_only
        run!
      }
      it("should install the plugin feature"){
        client_features.should include 'corvid:plugin'
      }
      it("should create resource directories"){
        'resources'.should exist_as_dir
        'resources/latest'.should exist_as_dir
      }
      it("should add rspec support"){
        'test/spec'.should exist_as_dir
        client_features.should include 'corvid:test_spec'
      }
    end
  end
end
