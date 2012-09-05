# encoding: utf-8
require_relative '../spec_helper'

describe "Plugins from a Client's perspective" do

  context "when plugin is installed (with no features)" do
    run_each_in_dynamic_fixture :client_with_plugin

    it("should load plugins' rake tasks"){
      invoke_rake! 'p1:hello'
      'hello.txt'.should be_file_with_content /p1$/
    }

    it("should not load rake tasks for features that aren't installed"){
      @quiet_sh= true
      invoke_rake('p1f1:hello').should be_false
    }

    it("should not load plugins that aren't in client's plugin list"){
      @quiet_sh= true
      File.write CONST::PLUGINS_FILE, BUILTIN_PLUGIN_DETAILS.to_yaml
      invoke_rake('p1:hello').should be_false
    }
  end

  context "when plugin and feature is installed" do
    run_each_in_dynamic_fixture :client_with_plugin_and_feature

    it("should load plugins' rake tasks"){
      invoke_rake! 'p1:hello'
      'hello.txt'.should be_file_with_content /p1$/
    }

    it("should load features' rake tasks"){
      invoke_rake! 'p1f1:hello'
      'hello.txt'.should be_file_with_content /p1:f1/
    }
  end
end
