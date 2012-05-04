# encoding: utf-8
require_relative '../spec_helper'

describe 'corvid init' do

  around :each do |ex|
    inside_fixture('bare'){ ex.run }
  end

  context 'init:test:unit' do
    it("should initalise unit test support"){
      invoke_corvid 'init:test:unit'
      files.should == [BOOTSTRAP_ALL, BOOTSTRAP_UNIT]
      file_should_match_template BOOTSTRAP_ALL
      file_should_match_template BOOTSTRAP_UNIT
    }

    it("should preserve the common bootstrap"){
      FileUtils.mkdir_p File.dirname(BOOTSTRAP_ALL)
      File.write BOOTSTRAP_ALL, '123'
      invoke_corvid 'init:test:unit'
      files.should == [BOOTSTRAP_ALL, BOOTSTRAP_UNIT]
      File.read(BOOTSTRAP_ALL).should == '123'
      file_should_match_template BOOTSTRAP_UNIT
    }
  end # init:test:unit

  context 'init:test:spec' do
    it("should initalise spec test support"){
      invoke_corvid 'init:test:spec'
      files.should == [BOOTSTRAP_ALL, BOOTSTRAP_SPEC]
      file_should_match_template BOOTSTRAP_ALL
      file_should_match_template BOOTSTRAP_SPEC
    }

    it("should preserve the common bootstrap"){
      FileUtils.mkdir_p File.dirname(BOOTSTRAP_ALL)
      File.write BOOTSTRAP_ALL, '123'
      invoke_corvid 'init:test:spec'
      files.should == [BOOTSTRAP_ALL, BOOTSTRAP_SPEC]
      File.read(BOOTSTRAP_ALL).should == '123'
      file_should_match_template BOOTSTRAP_SPEC
    }
  end # init:test:spec

end
