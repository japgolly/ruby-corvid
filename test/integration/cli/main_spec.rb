# encoding: utf-8
require_relative '../../spec_helper'
require 'corvid/cli/main'

describe Corvid::CLI::Main do
  run_each_in_empty_dir

  let(:available_tasks) do
    @capture_sh= true
    invoke_corvid!
#    puts @stdout
    @stdout.split($/).map{|l| /^\s*corvid +(\S+).*#.+$/ === l; $1 ? $1.dup : nil}.compact - %w[help]
  end

  it("when corvid not installed, provides task: init"){
    available_tasks.should equal_array %w[init]
  }

  it("when only corvid installed, provides tasks: init:plugin init:test:spec init:test:unit update:all update:corvid"){
    add_plugin! BUILTIN_PLUGIN
    add_feature! 'corvid:corvid'
    available_tasks.should equal_array %w[init:plugin init:test:spec init:test:unit update:all update:corvid]
  }

  it("when corvid:test_unit installed, -init:test:unit +new:test:unit"){
    add_plugin! BUILTIN_PLUGIN
    add_feature! 'corvid:test_unit'
    available_tasks.should_not include 'init:test:unit'
    available_tasks.should     include 'init:test:spec'
    available_tasks.should     include 'new:test:unit'
    available_tasks.should_not include 'new:test:spec'
  }

  it("when corvid:test_spec installed, -init:test:spec +new:test:spec"){
    add_plugin! BUILTIN_PLUGIN
    add_feature! 'corvid:test_spec'
    available_tasks.should     include 'init:test:unit'
    available_tasks.should_not include 'init:test:spec'
    available_tasks.should_not include 'new:test:unit'
    available_tasks.should     include 'new:test:spec'
  }

  it("when corvid:plugin installed, -init:plugin +new:plugin +new:feature"){
    add_plugin! BUILTIN_PLUGIN
    add_feature! 'corvid:plugin'
    available_tasks.should_not include 'init:plugin'
    available_tasks.should     include 'new:plugin'
    available_tasks.should     include 'new:feature'
  }
end
