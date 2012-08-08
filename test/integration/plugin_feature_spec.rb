# encoding: utf-8
require_relative '../spec_helper'

describe 'Plugin Feature' do
  include IntegrationTestDecoration

  run_all_in_empty_dir {
    invoke_corvid! %(
      init:project --no-#{RUN_BUNDLE} --no-test-unit --no-test-spec
      init:plugin --no-#{RUN_BUNDLE}
    )
    patch_corvid_gemfile
    patch_corvid_deps
    invoke_sh! 'bundle install --quiet'
  }

  it("should provide resource Rake tasks"){
    File.write 'resources/latest/symphony_x.txt', 'Iconoclast, 2011, TN#7, When All Is Lost <-- awesome song!'
    'resources/00001.patch'.should_not exist_as_file
    invoke_rake! 'res:new'
    'resources/00001.patch'.should exist_as_file
    File.read('resources/00001.patch').should include 'awesome song'
  }

  it("should add res-patch validity tests")
end

