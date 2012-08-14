# encoding: utf-8
require_relative '../../spec_helper'
require 'corvid/generators/update'
require 'corvid/generators/init'
require 'helpers/fixture-upgrading'

describe Corvid::Generator::Update do
  include Fixtures::Upgrading

  run_all_in_empty_dir {
    prepare_res_patches
    prepare_base_dirs do |ver|
      run_generator Corvid::Generator::Init, "project --test-unit --no-test-spec"
      'Gemfile'.should_not exist_as_a_file # Make sure it's not using real res-patches
      assert_installation ver, ver
    end
  }

  def run_update_task
    run_generator Corvid::Generator::Update, 'project'
  end

  context 'Corvid not installed' do
    run_each_in_empty_dir

    it("should refuse to update"){
      expect { run_update_task }.to raise_error
      get_files().should be_empty
    }
  end

  # not installed               - Done
  # up-to-date
  #      - without local mods   - Done
  #      - with local mods      - Done
  # out-of-date
  #      - without local mods   - Ignore
  #      - with local mods
  #        - non-conflicting    - Done
  #        - mergable           - Done
  #        - non-mergable       - Ignore

  def self.test_upgrade_capability(max_ver)
    1.upto(max_ver - 1) do |inst_ver|
      eval <<-EOB
        context 'clean upgrading from v#{inst_ver}' do
          run_all_in_sandbox_copy_of(#{inst_ver}) do
            File.write @ignore_file= 'local.txt', @ignore_msg= 'leave me alone'
            run_update_task
          end

          it("should upgrade from v#{inst_ver}->v#{max_ver}"){
            assert_installation #{max_ver}, #{max_ver}
          }
          it("should update the client's version number"){
            Corvid::Generator::Base.new.read_client_versions.should == {'corvid'=>#{max_ver}}
          }
          it("should ignore non-corvid files in the client dir"){
            @ignore_file.should exist_as_file
            File.read(@ignore_file).should == @ignore_msg
          }
        end
      EOB
    end
    eval <<-EOB
      context 'upgrading when client is up-to-date' do
        run_all_in_sandbox_copy_of(#{max_ver}) do
          @files_before= get_dir_entries()
          File.write 'corvid.A', 'whatever'
          run_update_task
        end

        it("should not change dirty files"){ File.read('corvid.A').should == 'whatever' }
        it("should not change up-to-date files"){ assert_installation #{max_ver}, #{max_ver}, %w[corvid.A] }
        it("should not change add or remove any files"){ get_dir_entries().should == @files_before }
      end
    EOB
  end

  context 'latest version available in corvid is v1' do
    run_all_with_corvid_resources_version 1
    test_upgrade_capability 1
  end

  context 'latest version available in corvid is v2' do
    run_all_with_corvid_resources_version 2
    test_upgrade_capability 2
  end

  context 'latest version available in corvid is v3' do
    run_all_with_corvid_resources_version 3
    test_upgrade_capability 3
  end

  context 'latest version available in corvid is v4' do
    run_all_with_corvid_resources_version 4
    test_upgrade_capability 4

    context 'dirty upgrading' do
      run_all_in_sandbox_copy_of(1) do
        File.write 'corvid.A', "--- sweet ---\ncorvid A made in v1\n"
        run_update_task
      end
      it("should patch dirty files"){
        File.read('corvid.A').should == "--- sweet ---\ncorvid A made in v1\nand in v2\nupdated in v3\n"
      }
      it("should upgrade other files normally"){
        assert_installation 4, 4, %w[corvid.A]
      }
      it("should update the client's version number"){
        Corvid::Generator::Base.new.read_client_versions.should == {'corvid'=>4}
      }
    end
  end

  describe '#extract_deployable_files' do
    %w[
      copy_file
      copy_file_unless_exists
      copy_executable
    ].each do |keyword|
      it("should understand #{keyword}"){
        filename= "xxx.#$$"
        c= "def install\n  #{keyword} '#{filename}'\nend"
        subject.send(:extract_deployable_files, c, 'a',1).should == [filename]
      }
    end
    it("should ignore commands it doesn't recognize"){
      c= "def install\n  what_the_hell 'filename'\nend"
      subject.send(:extract_deployable_files, c, 'a',1).should == []
    }
    it("should parse commands on the same line"){
      c= "def install(); copy_file 'f1'; copy_file 'f2'; end"
      subject.send(:extract_deployable_files, c, 'a',1).should == %w[f1 f2]
    }
  end
end
