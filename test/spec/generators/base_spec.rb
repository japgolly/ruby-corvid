# encoding: utf-8
require_relative '../../spec_helper'
require 'corvid/generators/base'

describe Corvid::Generator::Base do
  def source_root; $corvid_global_thor_source_root; end

  class X < Corvid::Generator::Base
    no_tasks {
      public :rpm, :with_latest_resources
    }
  end

  class Y < Corvid::Generator::Base
    no_tasks {
      public :rpm, :with_latest_resources
      attr_writer :rpm
    }
  end

  describe '#with_latest_resources' do
    it("should reuse an existing res-patch deployment"){
      x= X.new
      y= Y.new
      made_it_in= false

      [x,y].each do |t|
        t.rpm.instance_eval do
          def count; @count; end
          def with_resources(ver)
            @count ||= 0
            @count += 1
            yield
          end
        end
      end

      def count(x,y); (x.rpm.count || 0) + (y.rpm.count || 0); end

      x.with_latest_resources {
        count(x,y).should == 1

        y.with_latest_resources {
          count(x,y).should == 1

          x.with_latest_resources {
            count(x,y).should == 1
            made_it_in= true
          }
        }
      }
      made_it_in.should == true
    }

    it("should reset the templates directory when done"){
      Base= Corvid::Generator::Base
      X.new.with_latest_resources {
        source_root.should_not be_nil
        X.new.with_latest_resources {
          source_root.should_not be_nil
        }
        source_root.should_not be_nil
      }
      source_root.should be_nil
    }

  end

  describe '#feature_installer' do
    def installer_for(code)
      subject.stub feature_installer_file: 'as.rb'
      File.stub exist?: true
      File.should_receive(:read).once.and_return(code)
      subject.send(:feature_installer!,'dir','mock')
    end

    it("should allow declarative definition of install"){
      f= installer_for "install{ copy_file 'hehe'; 123 }"
      subject.should_receive(:copy_file).with('hehe').once
      f.install().should == 123
    }
    it("should allow declarative definition of update"){
      f= installer_for "update{ copy_file 'hehe2'; :no }"
      subject.should_receive(:copy_file).with('hehe2').once
      f.update().should == :no
    }
    it("should pass a version argument to update"){
      f= installer_for "update{|v| v*v }"
      f.update(3).should == 9
    }
    it("should allow declarative definition of values (as opposed to blocks)"){
      stub_const "#{Corvid::Generator::Base}::FEATURE_INSTALLER_VALUES_DEFS", %w[since_ver]
      f= installer_for "since_ver 2"
      f.since_ver().should == 2
    }
    it("should fail when no block passed to install"){
      expect { installer_for "install" }.to raise_error
    }
    it("should respond_to? provided values only"){
      f= installer_for "install{ 2 }"
      f.respond_to?(:install).should == true
      f.respond_to?(:update).should == false
    }
  end

  describe "#install_feature" do
    it("should fail if client resource version is prior to first feature version"){
      subject.stub read_client_version!: 3
      subject.stub read_client_features!: []
      f= mock 'feature b'
      f.should_receive(:since_ver).at_least(:once).and_return(4)
      subject.feature_registry= fr= mock 'feature registry'
      fr.should_receive(:instance_for).with('a:b').once.and_return(f)
      subject.should_not_receive :with_resources
      expect{
        subject.send :install_feature, 'a', 'b'
      }.to raise_error /update/
    }

    it("should do nothing if feature already installed"){
      subject.stub read_client_version!: 3
      subject.stub read_client_features!: ['a:b']
      subject.stub :say
      subject.should_not_receive :with_resources
      subject.send :install_feature, 'a', 'b'
    }
  end

  describe '#add_plugin' do
    run_all_in_empty_dir { Dir.mkdir '.corvid' }
    before(:each){ File.delete CONST::PLUGINS_FILE if File.exists? CONST::PLUGINS_FILE }

    it("should create the plugins file if it doesnt exist yet"){
      subject.send :add_plugin, 'corvid', BUILTIN_PLUGIN.new
      assert_plugins BUILTIN_PLUGIN_DETAILS
    }

    it("should add new plugins to the plugin file"){
      before= {'xxx'=>{path: 'xpath', class: 'X'}}.freeze
      File.write CONST::PLUGINS_FILE, before.to_yaml
      subject.send :add_plugin, 'corvid', BUILTIN_PLUGIN.new
      assert_plugins before.merge BUILTIN_PLUGIN_DETAILS
    }

    it("should replace existing plugin details if they differ") {
      File.write CONST::PLUGINS_FILE, {'corvid'=>{path: 'xpath', class: 'X'}}.to_yaml
      subject.send :add_plugin, 'corvid', BUILTIN_PLUGIN.new
      assert_plugins BUILTIN_PLUGIN_DETAILS
    }
  end
end
