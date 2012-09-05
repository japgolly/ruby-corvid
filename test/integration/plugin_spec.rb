# encoding: utf-8
require_relative '../spec_helper'

describe 'Plugin Integration Test' do

  run_each_in_fixture 'plugin'

  it("should load plugins' rake tasks"){

    # TODO move
    gsub_files! %r|(?<![./a-z])\.\./\.\./\.\./\.\.(?![./a-z])|, "#{CORVID_ROOT}" \
      ,'plugin_project/Gemfile.lock', 'plugin_project/Gemfile', 'plugin_project/.corvid/Gemfile' \
      ,'client_project/Gemfile.lock', 'client_project/Gemfile', 'client_project/.corvid/Gemfile'

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
