# encoding: utf-8
require_relative '../spec_helper'

describe 'Plugin Integration Test' do

  run_each_in_fixture 'plugin'

  it("should only load specified plugins"){
    File.write CONST::PLUGINS_FILE, BUILTIN_PLUGIN_DETAILS.to_yaml
    invoke_rake('mock:hello').should be_false
  }

  it("should load plugins' rake tasks"){
    invoke_rake! 'mock:hello'
    'hello.txt'.should exist_as_file
  }
end
