# encoding: utf-8
require_relative '../spec_helper'

describe 'Plugin Integration Test' do

  run_each_in_fixture 'plugin'

  it("should load plugins' rake tasks"){
    Dir.chdir 'client_project' do
      invoke_rake! 'p1:hello'
      'hello.txt'.should be_file_with_content /p1$/
    end
  }

  it("should only load specified plugins"){
    @quiet_sh= true
    Dir.chdir 'client_project' do
      File.write CONST::PLUGINS_FILE, BUILTIN_PLUGIN_DETAILS.to_yaml
      invoke_rake('p1:hello').should be_false
    end
  }
end
