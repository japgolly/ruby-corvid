# encoding: utf-8
require_relative 'spec_helper'
require 'corvid/res_patch_manager'

describe 'corvid template upgrades' do

  around :each do |ex|
    @tmp_dir ? ex.run : inside_empty_dir{ ex.run }
  end

  def upgrade_dir(ver=nil)
    d= "#{CORVID_ROOT}/test/fixtures/upgrades"
    d+= '/%d' % [ver] if ver
    d
  end

  def populate_with(ver)
    FileUtils.cp_r "#{upgrade_dir ver}/.", '.'
  end

  def migrate(from_ver, to_ver)
    m= Migration.new
    m.send :with_reconstruction_dir, upgrade_dir do
      m.send :migrate, from_ver, to_ver, Dir.pwd
    end
  end

  def get_files
    Dir.glob('**/*',File::FNM_DOTMATCH).select{|f| File.file? f }.sort
  end

  def assert_files(src_dir, exceptions={})
    filelist= Dir.chdir(src_dir){
      Dir.glob('**/*',File::FNM_DOTMATCH).select{|f| File.file? f }
        #.reject{|f| f =~ /corvid_migration-rename.yml/}
    } + exceptions.keys
    filelist.uniq!
    get_files.should == filelist.sort
    filelist.each do |f|
      expected= exceptions[f] || File.read("#{src_dir}/#{f}")
      File.read(f).should == expected
    end
  end

  context 'clean slate' do
    def test_clean_install(ver)
      migrate nil, ver
      assert_files upgrade_dir(ver)
    end
    it("should install 001"){ test_clean_install 1 }
    it("should install 002"){ test_clean_install 2 }
    it("should install 003"){ test_clean_install 3 }
  end

  context 'clean upgrading' do
    def test_clean_upgrade(from,to)
      populate_with from
      migrate from, to
      assert_files upgrade_dir(to)
    end
    it("should upgrade from 001 to 002"){ test_clean_upgrade 1,2 }
    it("should upgrade from 001 to 003"){ test_clean_upgrade 1,3 }
    it("should upgrade from 002 to 003"){ test_clean_upgrade 2,3 }
  end

  context 'dirty upgrading' do
    def copy_file(ver, filename)
      FileUtils.mkdir_p File.dirname(filename)
      FileUtils.cp "#{upgrade_dir ver}/#{filename}", filename
    end
    it("should upgrade from 000 to 002 - v2 file manually copied"){
      copy_file 2, "stuff/.hehe"
      migrate 0, 2
      assert_files upgrade_dir(2)
    }
    it("should upgrade from 000 to 002 - v1 file manually copied"){
      copy_file 1, "stuff/.hehe"
      migrate 0, 2
      assert_files upgrade_dir(2)
    }
    it("should upgrade from 001 to 002 - v1 file edited"){
      populate_with 1
      File.write 'stuff/.hehe', "hehe\n\nawesome"
      migrate 1, 2
      assert_files upgrade_dir(2), 'stuff/.hehe' => "hehe2\n\nawesome"
    }
    it("should upgrade from 001 to 003 - v2 file manually copied"){
      populate_with 1
      copy_file 2, "stuff/.hehe"
      migrate 1, 3
      assert_files upgrade_dir(3)
    }
    it("should upgrade from 002 to 003 - file deleted in v3 edited"){
      populate_with 2
      File.write 'v2.txt', "Before\nv2 bro\nAfter"
      migrate 2, 3
      assert_files upgrade_dir(3), 'v2.txt' => "Before\nAfter"
    }
    #it("should upgrade from 001 to 003 - v2 file edited"){
    #  populate_with 1
    #  File.write 'stuff/.hehe', "hehe2\n\nawesome"
    #  migrate 1, 3
    #  assert_files upgrade_dir(3), 'stuff/.hehe' => "hehe3\n\nawesome"
    #}
  end

  #---------------------------------------------------------------------------------------------------------------------

  context 'Template packages' do
    def copy_to(ver, dir)
      FileUtils.cp_r "#{upgrade_dir ver}/.", dir
    end

    def create_pkg
      Migration.new(res_patch_dir: 'mig').create_res_patch 'a','b'
    end

    def deploy_pkg(ver=nil)
      %w[a b r].each{|d| FileUtils.rm_rf d if Dir.exists?(d) }
      Dir.mkdir 'r'
      Migration.new(res_patch_dir: 'mig').deploy_res_patches 'r', ver
      if block_given?
        Dir.chdir('r'){ yield }
      end
    end

    def deploy_latest
      %w[a b r].each{|d| FileUtils.rm_rf d if Dir.exists?(d) }
      Migration.new(res_patch_dir: 'mig').deploy_latest_res_patch 'r'
      if block_given?
        Dir.chdir('r'){ yield }
      end
    end

    def shuffle
      FileUtils.rm_r 'a'
      File.rename 'b', 'a'
      Dir.mkdir 'b'
    end

    context 'Creation & deployment' do

      def create_patch_1
        %w[a b mig].each{|d| Dir.mkdir d unless Dir.exists? d }
        copy_to 1, 'b'
        create_pkg
        Dir['mig/**/*'].should == %w[mig/00001.patch]
      end
      def create_patch_2
        shuffle
        copy_to 2, 'b'
        create_pkg
        Dir['mig/**/*'].sort.should == %w[mig/00001.patch mig/00002.patch]
      end
      def create_patch_3
        shuffle
        copy_to 3, 'b'
        create_pkg
        Dir['mig/**/*'].sort.should == %w[mig/00001.patch mig/00002.patch mig/00003.patch]
      end

      def step_out_of_tmp_dir
        Dir.chdir @old_dir if @old_dir
        FileUtils.rm_rf @tmp_dir if @tmp_dir
        @old_dir= @tmp_dir= nil
      end

      context 'no res patches' do
        before(:all){
          @old_dir,@tmp_dir = inside_empty_dir
          Dir.mkdir 'mig'
        }
        after(:all){ step_out_of_tmp_dir }
        it("should do nothing when attemping to deploy latest"){ deploy_latest{ get_files.should be_empty } }
        it("should do nothing when attemping to deploy v0"){ deploy_pkg{ get_files.should be_empty } }
      end

      context '1 res patch' do
        before(:all){
          @old_dir,@tmp_dir = inside_empty_dir
          create_patch_1
        }
        after(:all){ step_out_of_tmp_dir }
        it("should deploy v1"){ deploy_pkg{ assert_files upgrade_dir 1 } }
        it("should deploy latest"){ deploy_latest{ assert_files upgrade_dir 1 } }
      end

      context '2 res patches' do
        before(:all){
          @old_dir,@tmp_dir = inside_empty_dir
          create_patch_1
          create_patch_2
        }
        after(:all){ step_out_of_tmp_dir }
        it("should deploy v2"){ deploy_pkg{ assert_files upgrade_dir 2 } }
        it("should deploy v1"){ deploy_pkg(1){ assert_files upgrade_dir 1 } }
        it("should deploy latest"){ deploy_latest{ assert_files upgrade_dir 2 } }
      end

      context '3 res patches' do
        before(:all){
          @old_dir,@tmp_dir = inside_empty_dir
          create_patch_1
          create_patch_2
          @patch_1= File.read 'mig/00001.patch'
          create_patch_3
        }
        after(:all){ step_out_of_tmp_dir }
        it("should deploy v3"){ deploy_pkg{ assert_files upgrade_dir 3 } }
        it("should deploy v2"){ deploy_pkg(2){ assert_files upgrade_dir 2 } }
        it("should deploy v1"){ deploy_pkg(1){ assert_files upgrade_dir 1 } }
        it("should not modify patches prior to n-1"){ File.read('mig/00001.patch').should == @patch_1 }
        it("should deploy latest"){ deploy_latest{ assert_files upgrade_dir 3 } }
      end

    end

    context 'Real packages' do
      def subject
        Migration.new res_patch_dir: File.expand_path('../../../resources',__FILE__)
      end
      it("should all be deployable"){
        subject.deploy_res_patches '.', 1
      }
    end
  end
end
