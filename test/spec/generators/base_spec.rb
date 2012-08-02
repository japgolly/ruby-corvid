# encoding: utf-8
require_relative '../spec_helper'
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

  context 'with_latest_resources()' do
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
end
