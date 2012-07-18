# encoding: utf-8
require_relative 'spec_helper'
require 'corvid/migration'

describe 'corvid template upgrades' do

  around :each do |ex|
    inside_empty_dir{ ex.run }
  end

  def upgrade_dir(ver=nil)
    d= "#{CORVID_ROOT}/test/fixtures/upgrades"
    d+= '/ver_%03d' % [ver] if ver
    d
  end

  def populate_with(ver)
    FileUtils.cp_r "#{upgrade_dir ver}/.", '.'
  end

  def migrate(options)
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
      migrate from: nil, to: ver, migration_dir: upgrade_dir
      assert_files upgrade_dir(ver)
    end
    it("should install 001"){ test_clean_install 1 }
    it("should install 002"){ test_clean_install 2 }
  end

  context 'clean upgrading' do
    def test_clean_upgrade(from,to)
      populate_with from
      migrate from: from, to: to, migration_dir: upgrade_dir
      assert_files upgrade_dir(to)
    end
    it("should upgrade from 001 to 002"){ test_clean_upgrade 1,2 }
  end

  context 'dirty upgrading' do
    def copy_file(ver, filename)
      FileUtils.mkdir_p File.dirname(filename)
      FileUtils.cp "#{upgrade_dir ver}/#{filename}", filename
    end
    it("should upgrade from 000 to 002 - v2 file manually copied"){
      copy_file 2, "stuff/.hehe"
      migrate from: 0, to: 2, migration_dir: upgrade_dir
      assert_files upgrade_dir(2)
    }
    it("should upgrade from 000 to 002 - v1 file manually copied"){
      copy_file 1, "stuff/.hehe"
      migrate from: 0, to: 2, migration_dir: upgrade_dir
      assert_files upgrade_dir(2)
    }
    it("should upgrade from 001 to 002 - v1 file edited"){
      populate_with 1
      File.write 'stuff/.hehe', "hehe\n\nawesome"
      migrate from: 1, to: 2, migration_dir: upgrade_dir
      assert_files upgrade_dir(2), 'stuff/.hehe' => "hehe2\n\nawesome"
    }
  end
end
