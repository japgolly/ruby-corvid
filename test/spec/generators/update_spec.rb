# encoding: utf-8
require_relative '../spec_helper'
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
    run_generator Corvid::Generator::Update, 'installed'
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
  #      - with local mods      - Ignore
  # out-of-date
  #      - without local mods   - Ignore
  #      - with local mods
  #        - non-conflicting    - Done
  #        - mergable           - TODO
  #        - non-mergable       - Ignore

  def self.test_upgrade_capability(max_ver)
    1.upto(max_ver - 1) do |inst_ver|
      eval <<-EOB
        context 'upgrading from v#{inst_ver}' do
          run_all_in_sandbox_copy_of(#{inst_ver}) do
            File.write @ignore_file= 'local.txt', @ignore_msg= 'leave me alone'
            run_update_task
          end

          it("should upgrade from v#{inst_ver}->v#{max_ver}"){
            assert_installation #{max_ver}, #{max_ver}
          }
          it("should update the client's version number"){
            Corvid::Generator::Base.new.read_deployed_corvid_version.should == #{max_ver}
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
          @files_before= get_files()
          run_update_task
        end

        it("should not change any files"){
          get_files().should == @files_before
          assert_installation #{max_ver}, #{max_ver}
        }
      end
    EOB
  end

  1.upto(Fixtures::Upgrading::MAX_VER) do |v|
    eval <<-EOB
      context 'latest version available in corvid is v#{v}' do
        run_all_with_corvid_resources_version #{v}
        test_upgrade_capability #{v}
      end
    EOB
  end

  context '#extract_deployable_files' do
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
