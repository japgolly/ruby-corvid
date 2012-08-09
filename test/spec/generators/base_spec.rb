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
end
