# encoding: utf-8
require_relative '../../spec_helper'
require 'corvid/generators/action_extentions'
require 'thor'

describe Corvid::Generator::ActionExtentions do

  run_each_in_empty_dir

  class MockGen < Thor
    include Thor::Actions
    include Corvid::Generator::ActionExtentions
    desc '',''; def add_line; add_line_to_file 'file', 'this is the text' end

    no_tasks{
      def omg; "123" end
      def evil; 666 end
    }
  end

  #---------------------------------------------------------------------------------------------------------------------

  describe "#add_line_to_file" do
    def run!; run_generator MockGen, 'add_line', false end

    it("creates the file when the file doesn't exist"){
      run!
      'file'.should exist_as_file
      File.read('file').chomp.should == 'this is the text'
    }

    context "the file already contains the line of text" do
      def test(content)
        File.write 'file', content
        run!
        File.read('file').should == content
      end
      it("does nothing when line is at start of file"){ test "this is the text\nthat's great" }
      it("does nothing when line is in middle of file"){ test "hehe\nthis is the text\nthat's great" }
      it("does nothing when line is at end of file without CR"){ test "hehe\nthis is the text" }
      it("does nothing when line is at end of file with CR"){ test "hehe\nthis is the text\n" }
    end

    context "when file exists and doesn't contain the line yet" do
      def test(content, append)
        File.write 'file', content
        run!
        File.read('file').should == content + append
      end
      it("adds the line of text and maintain the CR at EOF"){ test "hehe\nthat's great\n", "this is the text\n" }
      it("adds the line of text and maintain a lack of CR at EOF"){ test "hehe\nthat's great", "\nthis is the text" }
    end
  end

  #---------------------------------------------------------------------------------------------------------------------

  describe '#add_dependencies_to_gemfile' do
    before(:each){ $expect_bundle= nil }

    def test(gemfile_before, gemfile_after)
      File.write 'Gemfile', gemfile_before
      g= quiet_generator MockGen
      case $expect_bundle
        when nil   then g.stub :run_bundle_at_exit
        when false then g.should_not_receive :run_bundle_at_exit
        else            g.should_receive :run_bundle_at_exit
      end
      yield g
      'Gemfile'.should be_file_with_contents(gemfile_after).when_normalised_with(&:chomp)
    end

    def test1(gemfile_before, gemfile_after, *params)
      test(gemfile_before, gemfile_after) {|g| g.add_dependency_to_gemfile *params }
    end
    def test2(gemfile_before, gemfile_after, *params)
      test(gemfile_before, gemfile_after) {|g| g.add_dependencies_to_gemfile *params }
    end

    context "when dependency is new" do
      it("adds it to gemfile"){
        g= %[source :rubygems\ngroup :ci do\n  gem 'ci_reporter', require: false\nend]
        test1 g, %[#{g}\ngem "yard"], "yard"
        test2 g, %[#{g}\ngem "yard"], "yard"
      }

      it("adds it to gemfile with version"){
        g= %[source :rubygems\ngroup :ci do\n  gem 'ci_reporter', require: false\nend]
        test1 g, %[#{g}\ngem "yard", "= 2.0"], "yard", "= 2.0"
        test2 g, %[#{g}\ngem "yard", "= 2.0"], ["yard", "= 2.0"]
      }

      it("adds it to gemfile with options"){
        g= %[source :rubygems\ngroup :ci do\n  gem 'ci_reporter', require: false\nend]
        test1 g, %[#{g}\ngem "yard", platforms: :mri, path: "/tmp"], "yard", {platforms: :mri, path: "/tmp"}
        test2 g, %[#{g}\ngem "yard", platforms: :mri, path: "/tmp"], ["yard", {platforms: :mri, path: "/tmp"}]
      }

      it("adds multiple to gemfile"){
        g= %[source :rubygems\ngroup :ci do\n  gem 'ci_reporter', require: false\nend]
        test2 g, %[#{g}\ngem "yard"\ngem "golly-utils"], "yard", "golly-utils"
      }

      it("adds multiple to gemfile with params"){
        g= %[source :rubygems\ngroup :ci do\n  gem 'ci_reporter', require: false\nend]
        test2 g, %[#{g}\ngem "yard", platforms: :mri\ngem "abc", ">= 0.3", platforms: :jruby],
          ['yard', {platforms: :mri}], ['abc', '>= 0.3', {platforms: :jruby}]
      }

      it("adds when declared but commented out"){
        g= %[# gem "yard"]
        test1 g, %[#{g}\ngem "yard"], "yard"
      }
    end

    context "when dependency already declared" do
      it("do nothing when exact match found"){
        $expect_bundle= false
        g= %[source :rubygems\ngroup :ci do\n  gem 'ci_reporter', require: false\nend\ngem 'yard']
        test1 g, g, "yard"
        test1 g, g, "ci_reporter", require: false
        test2 g, g, "yard", ["ci_reporter", require: false]
      }

      it("do nothing when declared with different params"){
        # I think another method like set_dependency_option() would be more appropriate
        $expect_bundle= false
        g= %[source :rubygems\ngroup :ci do\n  gem 'ci_reporter', require: false\nend\ngem 'yard', '>=2']
        test1 g, g, "ci_reporter", require: true
        test1 g, g, "ci_reporter", '>=4', require: true
        test1 g, g, "yard", '>=3'
        test1 g, g, "yard", require: false
      }

      it("do nothing when declared one same line as other declaration"){
        $expect_bundle= false
        g= %[gem "abc"; gem "yard"; gem "def"]
        test1 g, g, "yard"
      }
    end

    context "running bundle" do
      it("calls run_bundle_at_exit() by default"){
        $expect_bundle= true
        g= %[source :rubygems\ngroup :ci do\n  gem 'ci_reporter', require: false\nend]
        test1 g, %[#{g}\ngem "yard"], "yard"
        test2 g, %[#{g}\ngem "yard"], "yard"
      }

      it("calls run_bundle_at_exit() if requested"){
        $expect_bundle= true
        g= %[source :rubygems\ngroup :ci do\n  gem 'ci_reporter', require: false\nend]
        test1 g, %[#{g}\ngem "yard"], "yard", run_bundle_at_exit: true
        test2 g, %[#{g}\ngem "yard"], "yard", run_bundle_at_exit: true
      }

      it("skips run_bundle_at_exit() if requested"){
        $expect_bundle= false
        g= %[source :rubygems\ngroup :ci do\n  gem 'ci_reporter', require: false\nend]
        test1 g, %[#{g}\ngem "yard"], "yard", run_bundle_at_exit: false
        test2 g, %[#{g}\ngem "yard"], "yard", run_bundle_at_exit: false
      }
    end

    it("fails when Gemfile doesn't exist"){
      expect{
        quiet_generator(MockGen).add_dependency_to_gemfile "yard"
      }.to raise_error /Gemfile/
    }
  end

  #---------------------------------------------------------------------------------------------------------------------

  describe '#template2' do
    let(:g) {
      g= quiet_generator(MockGen)
      g.stub :template
      g.stub :chmod
      g
    }

    it("removes .tt from end of filename"){
      g.should_receive(:template).once.with('hehe.rb.tt','hehe.rb')
      g.template2 'hehe.rb.tt'
    }

    it("doesn't remove .tt from middle of filename"){
      g.should_receive(:template).once.with('hehe.tt.rb','hehe.tt.rb')
      g.template2 'hehe.tt.rb'
    }

    it("substitutes tags in filename"){
      g.should_receive(:template).once.with('%omg%/%evil%-%evil%.rb','123/666-666.rb')
      g.template2 '%omg%/%evil%-%evil%.rb'
    }

    it("calls chmod when perms provided"){
      g.should_receive(:template).once.with('hehe.rb','hehe.rb').ordered
      g.should_receive(:chmod).once.with('hehe.rb',0123).ordered
      g.template2 'hehe.rb', perms: 0123
    }
  end
end
