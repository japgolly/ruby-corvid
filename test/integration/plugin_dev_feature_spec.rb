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
    File.write 'resources/latest/corvid-features/hot.rb', <<-EOB
      install{
        copy_file 'symphony_x.txt'
      }
    EOB

    invoke_rake! 'res:new'
    'resources/00001.patch'.should exist_as_file
    File.read('resources/00001.patch').should include 'awesome song'
  }

  it("User: install plugin and feature"){
    gsub_file! /(?<=auto_install_features ).+$/, '%w[hot]', 'lib/new_cool_plugin/cool_plugin.rb'
    Dir.mkdir 'clients'
    Dir.mkdir 'clients/_'
    Dir.chdir('clients/_'){
      copy_dynamic_fixture :bare_no_gemfile_lock
      invoke_sh! "../../bin/cool install"

      # Check plugin installed
      assert_plugins_installed %w[corvid cool]
      'Gemfile'.should be_file_with_content /new_cool_plugin/
      'Gemfile.lock'.should be_file_with_content /new_cool_plugin/

      # Check feature auto-installed
      assert_features_installed %w[corvid:corvid cool:hot]
      'symphony_x.txt'.should be_file_with_contents 'Iconoclast, 2011, TN#7, When All Is Lost <-- awesome song!'
    }
  }

  def with_client_copy(id='def')
    dir= "clients/#{id}"
    FileUtils.cp_r "clients/_", dir unless Dir.exists? dir
    Dir.chdir(dir){ yield }
  end

  it("Author: Create res-patch #2"){
    File.write 'resources/latest/symphony_x.txt', 'update bru'
    invoke_rake! 'res:new'
    'resources/00002.patch'.should exist_as_file
  }

  it("User: Update feature via corvid update"){
    with_client_copy(1) {
      invoke_corvid! 'update:all'
      'symphony_x.txt'.should be_file_with_contents 'update bru'
    }
  }

  it("User: Update feature via plugin update"){
    with_client_copy(2) {
      invoke_sh! '../../bin/cool update'
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
