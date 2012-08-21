# encoding: utf-8
require_relative '../spec_helper'

describe 'Plugin Development Feature' do
  include IntegrationTestDecoration

  run_all_in_empty_dir {
    copy_dynamic_fixture :new_hot_feature
  }

  it("Author: Create res-patch #1"){
    'resources/00001.patch'.should_not exist_as_file
    File.write 'resources/latest/symphony_x.txt', 'Iconoclast, 2011, TN#7, When All Is Lost <-- awesome song!'
    File.write 'resources/latest/corvid-features/hot.rb', "install{ copy_file 'symphony_x.txt' }"

    invoke_rake! 'res:new'
    'resources/00001.patch'.should exist_as_file
    File.read('resources/00001.patch').should include 'awesome song'
  }

  it("User: install plugin and feature"){
    gsub_file! /(?<=auto_install_features ).+$/, '%w[hot]', 'lib/corvid/cool_plugin.rb'
    Dir.mkdir '_'
    Dir.chdir('_'){
      copy_dynamic_fixture :bare
      invoke_sh! "../bin/cool install"
      assert_plugins_installed %w[corvid cool]
      assert_features_installed %w[corvid:corvid cool:hot]
      'symphony_x.txt'.should be_file_with_contents 'Iconoclast, 2011, TN#7, When All Is Lost <-- awesome song!'

      # TODO - Manually adding plugin to Gemfile - TODO delme"
#      gsub_file! /\z/, "\ngem 'cool_plugin', path: '..'", 'Gemfile'
    }
  }

  it("Author: Create res-patch #2"){
    File.write 'resources/latest/symphony_x.txt', 'update bru'
    invoke_rake! 'res:new'
    'resources/00002.patch'.should exist_as_file
  }

  xit("User: Update feature via corvid update"){
    FileUtils.cp_r '_', '_1'
    Dir.chdir('_1'){
      invoke_corvid! 'update:all'
      'symphony_x.txt'.should be_file_with_contents 'update bru'
    }
  }

  it("User: Update feature via plugin update"){
    FileUtils.cp_r '_', '_2'
    Dir.chdir('_2'){
      invoke_sh! '../bin/cool update'
      'symphony_x.txt'.should be_file_with_contents 'update bru'
    }
  }

  it("Author: prove tests validate resource patch validity"){
    invoke_rake('test').should == true

    p= 'resources/00001.patch'
    File.write p, File.read(p).sub(/[0-9]/,'f') # Corrupt a res-patch checksum
    @quiet_sh= true
    invoke_rake('test').should == false
  }
end
