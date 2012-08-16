# encoding: utf-8
require_relative '../../spec_helper'
require 'corvid/cli/plugin'

describe Corvid::CLI::Plugin do
  include IntegrationTestDecoration

# TODO Make something like dynamic & reusable fixtures
  run_all_in_empty_dir {
    invoke_corvid! %(
      init --no-#{RUN_BUNDLE} --no-test-unit --no-test-spec
      init:plugin --no-#{RUN_BUNDLE}
      new:plugin cool
    )
    patch_corvid_gemfile
    patch_corvid_deps
    invoke_sh! 'bundle install --quiet'

    Dir.mkdir 'ah'
  }

  around(:each){|ex| Dir.chdir('ah'){ ex.run }}

  def invoke_plugin_cli!(*args)
    invoke_sh! ['../bin/cool'] + args.flatten
  end

  let(:available_tasks) do
    @capture_sh= true
    invoke_plugin_cli!
#    puts @stdout
    @stdout.split($/).map{|l| /^\s*cool +(\S+).*#.+$/ === l; $1 ? $1.dup : nil}.compact - %w[help]
  end

  it("when not installed, provides tasks: install"){
    available_tasks.should equal_array %w[install]
  }

  it("can install itself"){
    invoke_plugin_cli! 'install'
    assert_plugins_installed({'cool'=>{path: 'corvid/cool_plugin', class: 'CoolPlugin'}})
  }

  it("when installed, provides tasks: update"){
    available_tasks.should equal_array %w[update]
  }

  it("runs the update task without failing (nothing to update though)"){
    invoke_plugin_cli! 'update'
  }
end
