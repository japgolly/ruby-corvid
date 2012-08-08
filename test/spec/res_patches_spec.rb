# encoding: utf-8
require_relative '../spec_helper'
require 'corvid/constants'
require 'corvid/res_patch_manager'
require 'corvid/generators/update'

describe "Actual resource patches" do
  run_each_in_empty_dir#_unless_in_one_already

  let(:rpm){ Corvid::ResPatchManager.new }

  # Test that we can explode n->1 without errors being raised.
  it("should be reconstructable back to v1"){
    rpm.with_resource_versions 1 do |dir|
      "#{dir}/1/Gemfile".should exist_as_file
    end
  }

  context 'Update vs Install' do

    class TestInstaller < Corvid::Generator::Base
      no_tasks{
        def install(feature, ver=nil)
          ver ||= rpm.latest_version
          with_resources(ver) {
            feature_installer!(feature).install
            add_feature feature
          }
        end
      }
    end

    def test(feature)
      # Install latest
      Dir.mkdir 'install'
      Dir.chdir 'install' do
        #run_generator TestInstaller, "install #{feature}"
        quiet_generator(TestInstaller).install feature
      end

      # Install old and upgrade
      Dir.mkdir 'upgrade'
      Dir.chdir 'upgrade' do
        #run_generator TestInstaller, "install #{feature} 1"
        quiet_generator(TestInstaller).install feature, 1
        quiet_generator(Corvid::Generator::Update).send :upgrade!, 1, @rpm.latest_version, [feature]
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

    BUILTIN_FEATURES.each do |feature|
      eval <<-EOB
        it("Testing built-in feature: #{feature}"){
          @rpm= rpm
          test '#{feature}'
        }
      EOB
    end
  end

end
