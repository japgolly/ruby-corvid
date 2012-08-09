# encoding: utf-8
require_relative '../spec_helper'
require 'corvid/constants'
require 'corvid/res_patch_manager'
require 'corvid/feature_manager'
require 'corvid/generators/update'

describe "Actual Resources" do
  LATEST_VER= Corvid::ResPatchManager.new.latest_version

  run_each_in_empty_dir

  let(:rpm){ Corvid::ResPatchManager.new }

  describe "Patches" do

    # Test that we can explode n->1 without errors being raised.
    it("should be reconstructable back to v1"){
      rpm.with_resource_versions 1 do |dir|
        "#{dir}/1/Gemfile".should exist_as_file
      end
    }
  end

  describe 'Feature Installers: Update vs Install' do

    class TestInstaller < Corvid::Generator::Base
      no_tasks{
        def install(feature, ver=nil)
          ver ||= rpm.latest_version
          # Hardcoded-logic here but all features apart from corvid, requrie corvid to be installed first.
          unless feature == 'corvid'
            Dir.mkdir '.corvid' unless Dir.exists?('.corvid')
            File.write Corvid::Constants::VERSION_FILE, ver
            File.write Corvid::Constants::FEATURES_FILE, %w[corvid].to_yaml
          end
          with_resources(ver) {
            feature_installer!(feature).install
            add_feature feature
          }
          File.delete Corvid::Constants::VERSION_FILE if File.exists?(Corvid::Constants::VERSION_FILE)
        end
      }
    end

    def test(feature, starting_version=1)
      # Install latest
      Dir.mkdir 'install'
      Dir.chdir 'install' do
        #run_generator TestInstaller, "install #{feature}"
        quiet_generator(TestInstaller).install feature
      end

      # Install old and upgrade
      Dir.mkdir 'upgrade'
      Dir.chdir 'upgrade' do
        quiet_generator(TestInstaller).install feature, starting_version
        quiet_generator(Corvid::Generator::Update).send :upgrade!, starting_version, @rpm.latest_version, [feature]
        File.delete Corvid::Constants::VERSION_FILE
      end

      # Compare directories
      files= get_files('upgrade')
      files.should equal_array get_files('install')
      get_dirs('upgrade').should equal_array get_dirs('install')
      files.each do |f|
        File.read("upgrade/#{f}").should == File.read("install/#{f}")
      end
    end

    it("should fail when update() has an extra step that's not in install()"){
      @rpm= Corvid::ResPatchManager.new "#{Fixtures::FIXTURE_ROOT}/invalid_res_patch-extra_update_step"
      expect{ test 'corvid' }.to raise_error /wtfff/
    }
    it("should fail when update() is missing a step that's in install()"){
      @rpm= Corvid::ResPatchManager.new "#{Fixtures::FIXTURE_ROOT}/invalid_res_patch-missing_update_step"
      expect{ test 'corvid' }.to raise_error /wtfff/
    }

    BUILTIN_FEATURES.each {|feature|
      f= Corvid::FeatureManager.instance_for(feature)
      unless f.since_ver == LATEST_VER
        eval <<-EOB
          it("Testing built-in feature: #{feature}"){
            @rpm= rpm
            test '#{feature}', f.since_ver
          }
        EOB
      end
    }

  end

end
