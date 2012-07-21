# encoding: utf-8
require_relative 'spec_helper'
require 'corvid/migration'

describe 'corvid template upgrades' do

  around :each do |ex|
    inside_empty_dir{ ex.run }
  end

  def upgrade_dir(ver=nil)
    d= "#{CORVID_ROOT}/test/fixtures/upgrades"
    d+= '/%d' % [ver] if ver
    d
  end

  def populate_with(ver)
    FileUtils.cp_r "#{upgrade_dir ver}/.", '.'
  end

  def migrate(options)
    #m= Migration.new migration_dir: options.delete(:migration_dir)
    #m.migrate options
    Migration.new.migrate options
  end

  def assert_files(src_dir, exceptions={})
    filelist= Dir.chdir(src_dir){
      Dir.glob('**/*',File::FNM_DOTMATCH).select{|f| File.file? f }
        #.reject{|f| f =~ /corvid_migration-rename.yml/}
    } + exceptions.keys
    filelist.uniq!
    Dir.glob('**/*',File::FNM_DOTMATCH).select{|f| File.file? f }
      .sort.should == filelist.sort
    filelist.each do |f|
      expected= exceptions[f] || File.read("#{src_dir}/#{f}")
      File.read(f).should == expected
    end
  end

  context 'clean slate' do
    def test_clean_install(ver)
      migrate from: nil, to: ver, ver_dir: upgrade_dir
      assert_files upgrade_dir(ver)
    end
    it("should install 001"){ test_clean_install 1 }
    it("should install 002"){ test_clean_install 2 }
    it("should install 003"){ test_clean_install 3 }
  end

  context 'clean upgrading' do
    def test_clean_upgrade(from,to)
      populate_with from
      migrate from: from, to: to, ver_dir: upgrade_dir
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
      migrate from: 0, to: 2, ver_dir: upgrade_dir
      assert_files upgrade_dir(2)
    }
    it("should upgrade from 000 to 002 - v1 file manually copied"){
      copy_file 1, "stuff/.hehe"
      migrate from: 0, to: 2, ver_dir: upgrade_dir
      assert_files upgrade_dir(2)
    }
    it("should upgrade from 001 to 002 - v1 file edited"){
      populate_with 1
      File.write 'stuff/.hehe', "hehe\n\nawesome"
      migrate from: 1, to: 2, ver_dir: upgrade_dir
      assert_files upgrade_dir(2), 'stuff/.hehe' => "hehe2\n\nawesome"
    }
    it("should upgrade from 001 to 003 - v2 file manually copied"){
      populate_with 1
      copy_file 2, "stuff/.hehe"
      migrate from: 1, to: 3, ver_dir: upgrade_dir
      assert_files upgrade_dir(3)
    }
    it("should upgrade from 002 to 003 - file deleted in v3 edited"){
      populate_with 2
      File.write 'v2.txt', "Before\nv2 bro\nAfter"
      migrate from: 2, to: 3, ver_dir: upgrade_dir
      assert_files upgrade_dir(3), 'v2.txt' => "Before\nAfter"
    }
    #it("should upgrade from 001 to 003 - v2 file edited"){
    #  populate_with 1
    #  File.write 'stuff/.hehe', "hehe2\n\nawesome"
    #  migrate from: 1, to: 3, ver_dir: upgrade_dir
    #  assert_files upgrade_dir(3), 'stuff/.hehe' => "hehe3\n\nawesome"
    #}
  end

  #---------------------------------------------------------------------------------------------------------------------

  context 'Template packages' do
    before :each do |ex|
      %w[a b mig].each{|d| Dir.mkdir d }
    end

    def copy_to(ver, dir)
      FileUtils.cp_r "#{upgrade_dir ver}/.", dir
    end

    def create_pkg(options={})
      options[:from] ||= 'a'
      options[:to] ||= 'b'
      Migration.new(migration_dir: 'mig').create_pkg_file options
    end

    def deploy_pkg(ver=nil)
      %w[a b r].each{|d| FileUtils.rm_rf d if Dir.exists?(d) }
      Dir.mkdir 'r'
      Migration.new(migration_dir: 'mig').deploy_pkg_file 'r', ver
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

      it("should create & deploy v1"){
        create_patch_1
        deploy_pkg{ assert_files upgrade_dir 1 }
      }

      it("should create & deploy v1, v2"){
        create_patch_1
        create_patch_2
#puts '_'*80;1.upto(2){|i| puts `cat mig/0000#{i}.patch`;puts '_'*80}
        deploy_pkg{ assert_files upgrade_dir 2 }
        deploy_pkg(1){ assert_files upgrade_dir 1 }
      }

      it("should create & deploy v1, v2, v3"){
        create_patch_1
        create_patch_2
        create_patch_3
#puts '_'*80;1.upto(3){|i| puts `cat mig/0000#{i}.patch`;puts '_'*80}
        deploy_pkg{ assert_files upgrade_dir 3 }
        deploy_pkg(2){ assert_files upgrade_dir 2 }
        deploy_pkg(1){ assert_files upgrade_dir 1 }
      }

      it("should not modify patches prior to n-1"){
        create_patch_1
        create_patch_2
        p1= File.read 'mig/00001.patch'
        create_patch_3
        File.read('mig/00001.patch').should == p1
      }
    end
  end
end
