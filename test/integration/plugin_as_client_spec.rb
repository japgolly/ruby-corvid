# encoding: utf-8
require_relative '../spec_helper'

describe "Plugins from a Client's perspective" do

  let(:available_tasks){ $available_tasks ||= available_tasks_for_corvid }

  shared_examples 'plugin-installed functionality' do
    it("Rake should load plugin's rake tasks"){
      invoke_rake! 'p1:hello'
      'hello.txt'.should be_file_with_content /p1$/
    }

    it("Corvid CLI should load plugin's corvid tasks"){
      available_tasks.should include 'p1:t1_task'
    }
  end

  context "when plugin is installed (with no features)" do
    run_each_in_dynamic_fixture :client_with_plugin
    after(:all){ $available_tasks= nil }

    include_examples 'plugin-installed functionality'

    it("Corvid CLI shouldn't load feature's corvid tasks"){
      available_tasks.should_not include 'p1:t2_task'
    }

    it("Rake shouldn't load tasks for features that aren't installed"){
      @quiet_sh= true
      invoke_rake('p1f1:hello').should be_false
    }

    it("Rake shouldn't load tasks for plugins that aren't in client's plugin list"){
      @quiet_sh= true
      File.write CONST::PLUGINS_FILE, BUILTIN_PLUGIN_DETAILS.to_yaml
      invoke_rake('p1:hello').should be_false
    }
  end

  context "when plugin and feature is installed" do
    run_each_in_dynamic_fixture :client_with_plugin_and_feature
    after(:all){ $available_tasks= nil }

    include_examples 'plugin-installed functionality'

    it("Corvid CLI should load feature's corvid tasks"){
      available_tasks.should include 'p1:t2_task'
    }

    it("Rake should load feature's rake tasks"){
      invoke_rake! 'p1f1:hello'
      'hello.txt'.should be_file_with_content /p1:f1/
    }
  end
end
