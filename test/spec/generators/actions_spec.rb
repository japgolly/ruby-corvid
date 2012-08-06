# encoding: utf-8
require_relative '../../spec_helper'
require 'corvid/generators/actions'
require 'thor'

describe Corvid::Generator::ActionExtentions do
  run_each_in_empty_dir

  class MockGen < Thor
    include Thor::Actions
    include Corvid::Generator::ActionExtentions

    desc '',''
    def add_line; add_line_to_file 'file', 'this is the text' end
  end

  context "#add_line_to_file" do
    def run!; run_generator MockGen, 'add_line', false end

    it("should create the file when the file doesn't exist"){
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
      it("should do nothing when line is at start of file"){ test "this is the text\nthat's great" }
      it("should do nothing when line is in middle of file"){ test "hehe\nthis is the text\nthat's great" }
      it("should do nothing when line is at end of file without CR"){ test "hehe\nthis is the text" }
      it("should do nothing when line is at end of file with CR"){ test "hehe\nthis is the text\n" }
    end

    context "when file exists and doesn't contain the line yet" do
      def test(content, append)
        File.write 'file', content
        run!
        File.read('file').should == content + append
      end
      it("should add the line of text and maintain the CR at EOF"){ test "hehe\nthat's great\n", "this is the text\n" }
      it("should add the line of text and maintain a lack of CR at EOF"){ test "hehe\nthat's great", "\nthis is the text" }
    end
  end
end
