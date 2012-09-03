# encoding: utf-8
require_relative '../../spec_helper'
require 'corvid/generators/actions'
require 'thor'

describe Corvid::Generator::ActionExtentions do

  run_each_in_empty_dir

  class MockGen < Thor
    include Thor::Actions
    include Corvid::Generator::ActionExtentions
    desc '',''; def add_line; add_line_to_file 'file', 'this is the text' end
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
    def test(gemfile_before, gemfile_after)
      File.write 'Gemfile', gemfile_before
      g= quiet_generator MockGen
      yield g
      'Gemfile'.chomp.should be_file_with_contents gemfile_after.chomp
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
        g= %[source :rubygems\ngroup :ci do\n  gem 'ci_reporter', require: false\nend\ngem 'yard']
        test1 g, g, "yard"
        test1 g, g, "ci_reporter", require: false
        test2 g, g, "yard", ["ci_reporter", require: false]
      }

      it("do nothing when declared with different params"){
        # I think another method like set_dependency_option() would be more appropriate
        g= %[source :rubygems\ngroup :ci do\n  gem 'ci_reporter', require: false\nend\ngem 'yard', '>=2']
        test1 g, g, "ci_reporter", require: true
        test1 g, g, "ci_reporter", '>=4', require: true
        test1 g, g, "yard", '>=3'
        test1 g, g, "yard", require: false
      }

      it("do nothing when declared one same line as other declaration"){
        g= %[gem "abc"; gem "yard"; gem "def"]
        test1 g, g, "yard"
      }
    end

    it("fails when Gemfile doesn't exist"){
      expect{
        quiet_generator(MockGen).add_dependency_to_gemfile "yard"
      }.to raise_error /Gemfile/
    }
  end
end
