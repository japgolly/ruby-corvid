require 'thor'
require 'active_support/core_ext/string/inflections'
require 'active_support/inflections'

RAVEN_ROOT= File.expand_path('../..',__FILE__)

module Raven
  module Generator
    class Base < Thor
      include Thor::Actions

      def self.source_root
        "#{RAVEN_ROOT}/templates"
      end
      def self.inherited(c)
        c.class_eval "def self.source_root; ::#{self}.source_root end"
      end

      protected

      def copy_file_unless_exists(src, tgt=nil, options={})
        tgt ||= src
        copy_file src, tgt, options unless File.exists?(tgt)
      end
    end

    class InitTest < Base
      namespace 'init:test'

      desc 'unit', 'Adds support for unit tests.'
      def unit
        copy_file_unless_exists 'test/bootstrap/all.rb'
        copy_file 'test/bootstrap/unit.rb'
      end

      desc 'spec', 'Adds support for specifications.'
      def spec
        copy_file_unless_exists 'test/bootstrap/all.rb'
        copy_file 'test/bootstrap/spec.rb'
      end
    end

    class Test < Base
      namespace :test
      argument :name, :type => :string

      desc 'unit', 'Generates a new unit test.'
      def unit
        template 'test/unit/%src%_test.rb.tt', "test/unit/#{src}_test.rb"
      end

      desc 'spec', 'Generates a new specification.'
      def spec
        template 'test/spec/%src%_spec.rb.tt', "test/spec/#{src}_spec.rb"
      end

      private

      def src
        name.underscore.gsub /^[\\\/]+|\.rb$/, ''
      end

      def bootstrap_dir
        '../'*src.split(/[\\\/]+/).size + 'bootstrap'
      end

      def testcase_name
        src.split(/[\\\/]+/).last.camelcase
      end

      def subject
        src.camelcase
      end

    end
  end
end
