require 'thor'
require 'active_support/core_ext/string/inflections'
require 'active_support/inflections'

RAVEN_ROOT= File.expand_path('../..',__FILE__)

module Raven
  module Generator
    class Base < Thor
      def self.source_root
        "#{RAVEN_ROOT}/templates"
      end
      def self.inherited(c)
        c.class_eval "def self.source_root; ::#{self}.source_root end"
      end

      protected

      def copy_file_unless_exists(src, tgt=nil, options={})
        tgt ||= src.sub /\.tt$/, ''
        copy_file src, tgt, options unless File.exists?(tgt)
      end
    end

    class UnitTest < Base
      include Thor::Actions

      argument :name, :type => :string
      desc 'unit_test name', 'Generates a unit test.'
      def unit_test
        copy_file_unless_exists 'test/bootstrap/all.rb.tt'
        copy_file_unless_exists 'test/bootstrap/unit.rb.tt'
        template 'test/unit/%src%_test.rb.tt', "test/unit/#{src}_test.rb"
      end

      private

      def src
        name.underscore.gsub /^[\\\/]+|\.rb$/, ''
      end

      def bootstrap
        '../'*src.split(/[\\\/]+/).size + 'bootstrap/unit'
      end

      def testcase_name
        src.split(/[\\\/]+/).last.camelcase
      end

    end
  end
end
