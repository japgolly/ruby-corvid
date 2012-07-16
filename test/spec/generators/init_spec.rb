# encoding: utf-8
require_relative '../spec_helper'

describe 'corvid init' do

  around :each do |ex|
    inside_fixture('bare'){
      File.delete '.corvid/Gemfile'
      ex.run
    }
  end

  context 'init:test:unit' do
    it("should initalise unit test support"){
      invoke_corvid! "init:test:unit --no-#{RUN_BUNDLE}"
      file_should_match_template BOOTSTRAP_ALL
      file_should_match_template BOOTSTRAP_UNIT
      Dir.exists?('test/unit').should == true
    }

    it("should preserve the common bootstrap"){
      FileUtils.mkdir_p File.dirname(BOOTSTRAP_ALL)
      File.write BOOTSTRAP_ALL, '123'
      invoke_corvid! "init:test:unit --no-#{RUN_BUNDLE}"
      File.read(BOOTSTRAP_ALL).should == '123'
      file_should_match_template BOOTSTRAP_UNIT
      Dir.exists?('test/unit').should == true
    }
  end # init:test:unit

  context 'init:test:spec' do
    it("should initalise spec test support"){
      invoke_corvid! "init:test:spec --no-#{RUN_BUNDLE}"
      file_should_match_template BOOTSTRAP_ALL
      file_should_match_template BOOTSTRAP_SPEC
      Dir.exists?('test/spec').should == true
    }

    it("should preserve the common bootstrap"){
      FileUtils.mkdir_p File.dirname(BOOTSTRAP_ALL)
      File.write BOOTSTRAP_ALL, '123'
      invoke_corvid! "init:test:spec --no-#{RUN_BUNDLE}"
      File.read(BOOTSTRAP_ALL).should == '123'
      file_should_match_template BOOTSTRAP_SPEC
      Dir.exists?('test/spec').should == true
    }
  end # init:test:spec

end
