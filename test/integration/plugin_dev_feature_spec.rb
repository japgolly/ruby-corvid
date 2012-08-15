# encoding: utf-8
require_relative '../spec_helper'

describe 'Plugin Development Feature' do
  include IntegrationTestDecoration

  run_all_in_empty_dir {
    invoke_corvid! %(
      init --no-#{RUN_BUNDLE} --no-test-unit --no-test-spec
      init:plugin --no-#{RUN_BUNDLE}
      new:plugin cool
    )
    patch_corvid_gemfile
    patch_corvid_deps
    invoke_sh! 'bundle install --quiet'
  }

  it("should have a CLI that can install itself"){
    bin= File.join Dir.pwd, 'bin/cool'
    inside_empty_dir{
      invoke_sh! [bin, 'install']
      assert_plugins_installed({'cool'=>{path: 'corvid/cool_plugin', class: 'CoolPlugin'}})
    }
  }

  it("should provide resource Rake tasks"){
    File.write 'resources/latest/symphony_x.txt', 'Iconoclast, 2011, TN#7, When All Is Lost <-- awesome song!'
    'resources/00001.patch'.should_not exist_as_file

    invoke_rake! 'res:new'
    'resources/00001.patch'.should exist_as_file
    File.read('resources/00001.patch').should include 'awesome song'
  }

  it("should add tests that verify resource patch validity"){
    invoke_rake('test').should == true

    p= 'resources/00001.patch'
    File.write p, File.read(p).sub(/[0-9]/,'f') # Corrupt a res-patch checksum
    @quiet_sh= true
    invoke_rake('test').should == false
  }

end

