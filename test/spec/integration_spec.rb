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
    Dir.chdir($dir){ ex.run }
  end

  it("should initialise project"){
    invoke_corvid! 'init:project --test-unit --no-test-spec'
  }

  it("should support unit tests"){
    # Create lib and test
    invoke_sh! 'echo "class Hehe; def num; 123 end end" > lib/hehe.rb'
    invoke_corvid! 'new:test:unit hehe'
    invoke_sh! %!sed -i 's/# TODO/def test_hehe; assert_equal 123, Hehe.new.num end/' test/unit/hehe_test.rb!

    # Invoke directly and check coverage
    invoke_sh! 'ruby test/unit/hehe_test.rb', 'coverage'=>'1'
    File.exist?('target/coverage/index.html').should == true

    # Redo with rake
    invoke_sh! 'bundle exec rake clean'
    File.exist?('target/coverage/index.html').should == false
    invoke_sh! 'bundle exec rake test', 'coverage'=>'1'
    File.exist?('target/coverage/index.html').should == true
  }
end
