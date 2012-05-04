# encoding: utf-8
require_relative 'spec_helper'

describe 'Integration test' do
  before :all do
    $dir = Dir.mktmpdir
  end

  after :all do
    if $dir
      FileUtils.rm_rf $dir
      $dir = nil
    end
  end

  around :each do |ex|
    clean
    Dir.chdir($dir){ ex.run }
  end

  def clean
    return unless Dir.exist?('target')
    invoke_sh! 'bundle exec rake clean'
    Dir.exist?('target').should == false
  end

  it("should initialise project"){
    invoke_corvid! 'init:project --test-unit --test-spec'
    invoke_sh! 'echo "class Hehe; def num; 123 end end" > lib/hehe.rb'
  }

  it("should support unit tests"){
    # Create unit test
    invoke_corvid! 'new:test:unit hehe'
    invoke_sh! %!sed -i 's/# TODO/def test_hehe; assert_equal 123, Hehe.new.num end/' test/unit/hehe_test.rb!

    # Invoke via rake
    invoke_sh! 'bundle exec rake test:unit', 'coverage'=>'1'
    File.exist?('target/coverage/index.html').should == true

    # Rerun directly
    clean
    invoke_sh! 'ruby test/unit/hehe_test.rb', 'coverage'=>'1'
    File.exist?('target/coverage/index.html').should == true
  }

  it("should support specs"){
    # Create spec
    invoke_corvid! 'new:test:spec hehe'
    invoke_sh! %!sed -i 's/# TODO/it("num"){ subject.num.should == 123 }/' test/spec/hehe_spec.rb!

    # Invoke via rake
    invoke_sh! 'bundle exec rake test:spec', 'coverage'=>'1'
    File.exist?('target/coverage/index.html').should == true

    # Rerun directly
    clean
    invoke_sh! 'bin/rspec test/spec/hehe_spec.rb', 'coverage'=>'1'
    File.exist?('target/coverage/index.html').should == true
  }
end
