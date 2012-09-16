# encoding: utf-8
require_relative '../../bootstrap/spec'

$weave_corvid_guard_ext= false
require 'corvid/builtin/guard'

describe Corvid::Builtin::GuardExt do
  let(:subject){ Object.new.tap{|o| o.extend described_class }}

  describe '#read_rspec_options' do
    before(:each){
      subject.stub fast_only?: false
    }


    context "when file exists" do
      def test(input,output)
        File.stub exists?: true, read: input
        o= subject.read_rspec_options '.'
        o.should == output
      end

      it("joins lines"){
        test "--color\n--abc \n--def", '--color --abc --def'
      }
      it("removes comments"){
        test "--color #hehe\n--abc   #  dude what?? \n--def # bye", '--color --abc --def'
      }
      it("changes random order into default"){
        test "--color\n--order random\n--hehe", '--color --order default --hehe'
        test "--color\n-O random\n--hehe", '--color --order default --hehe'
        test "--color\n-O rand\n--hehe", '--color --order default --hehe'
      }
      it("ignores slow tests when fast_only? is true"){
        subject.should_receive(:fast_only?).and_return(true)
        test "--abc", '--abc --tag ~slow'
      }
    end

    context "when file doesn't exist" do
      before(:each){
        File.stub exists?: false
      }
      it("returns nil"){
        subject.read_rspec_options('.').should be_nil
      }
      it("ignores slow tests when fast_only? is true"){
        subject.should_receive(:fast_only?).and_return(true)
        subject.read_rspec_options('.').should == '--tag ~slow'
      }
    end
  end

  describe '#determine_project_name' do
    it("works"){
      Dir.stub :[] => [], :pwd => 'hehe'
      subject.determine_project_name().should == 'hehe'
    }
#    it("quotes for regex"){
#      Dir.stub :[] => [], :pwd => 'a+b'
#      subject.determine_project_name().should == 'a\+b'
#    }
  end
end
