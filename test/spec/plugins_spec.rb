# encoding: utf-8
require_relative 'spec_helper'

describe 'Plugin system' do

  around :each do |ex|
    inside_fixture('plugin',true){ ex.run }
  end

  it("should only load specified plugins"){
    File.delete '.corvid/plugins.yml'
    expect{ invoke_rake! 'mock:hello' }.to raise_error
  }

  it("should load plugins' rake tasks"){
    invoke_rake! 'mock:hello'
    File.exist?('hello.txt').should == true
  }
end
