# encoding: utf-8
require_relative '../spec_helper'
require 'corvid/generators/init'

describe Corvid::Generator::Init::Test do
  around :each do |ex|
    inside_fixture('bare'){ ex.run }
  end

  context 'init:test:unit' do
    it("should initalise unit test support"){
      described_class.start ["unit", "--no-#{RUN_BUNDLE}"]
      test_bootstraps true, true, false
      Dir.exists?('test/unit').should == true
    }

    it("should preserve the common bootstrap"){
      FileUtils.mkdir_p File.dirname(BOOTSTRAP_ALL)
      File.write BOOTSTRAP_ALL, '123'
      described_class.start ["unit", "--no-#{RUN_BUNDLE}"]
      File.read(BOOTSTRAP_ALL).should == '123'
      test_bootstraps nil, true, false
      Dir.exists?('test/unit').should == true
    }
  end # init:test:unit

  context 'init:test:spec' do
    it("should initalise spec test support"){
      described_class.start ["spec", "--no-#{RUN_BUNDLE}"]
      test_bootstraps true, false, true
      Dir.exists?('test/spec').should == true
    }

    it("should preserve the common bootstrap"){
      FileUtils.mkdir_p File.dirname(BOOTSTRAP_ALL)
      File.write BOOTSTRAP_ALL, '123'
      described_class.start ["spec", "--no-#{RUN_BUNDLE}"]
      File.read(BOOTSTRAP_ALL).should == '123'
      test_bootstraps nil, false, true
      Dir.exists?('test/spec').should == true
    }
  end # init:test:spec

  def test_bootstraps(all, unit, spec)
    test_bootstrap BOOTSTRAP_ALL,  all,  true,  false, false unless all.nil?
    test_bootstrap BOOTSTRAP_UNIT, unit, false, true,  false unless unit.nil?
    test_bootstrap BOOTSTRAP_SPEC, spec, false, false, true  unless spec.nil?
  end

  def test_bootstrap(file, expected, all, unit, spec)
    File.exists?(file).should == expected
    if expected
      c= File.read(file)
      c.send all  ? :should : :should_not, include('corvid/test/bootstrap/all')
      c.send unit ? :should : :should_not, include('unit')
      c.send spec ? :should : :should_not, include('spec')
    end
  end
end
