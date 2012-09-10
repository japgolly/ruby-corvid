# encoding: utf-8
require_relative '../../bootstrap/integration'
require 'corvid/cli/plugin'

describe Corvid::CLI::Plugin do
  include IntegrationTestDecoration

  run_all_in_empty_dir {
    copy_dynamic_fixture :new_cool_plugin
    Dir.mkdir 'ah'
    File.write 'ah/Gemfile', ''
  }
  around(:each){|ex|
    Dir.chdir('ah'){ ex.run }
  }

  def invoke_plugin_cli!(*args)
    invoke_sh! ['../bin/cool'] + args.flatten
  end

  let(:available_tasks) do
    available_tasks_for 'cool', &:invoke_plugin_cli!
#    puts @stdout
  end

  it("when not installed, provides tasks: install"){
    available_tasks.should equal_array %w[install]
  }

  it("can install itself"){
    invoke_plugin_cli! "install", "--no-#{RUN_BUNDLE}"
    assert_plugins_installed({'cool'=>{path: 'new_cool_plugin/cool_plugin', class: 'NewCoolPlugin::CoolPlugin'}})
  }

  it("when installed, provides tasks: update"){
    available_tasks.should equal_array %w[update]
  }

  it("runs the update task without failing (nothing to update though)"){
    invoke_plugin_cli! 'update'
  }
end
