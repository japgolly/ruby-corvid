require 'corvid/environment'
require 'corvid/res_patch_manager'

require 'thor'
require 'active_support/core_ext/string/inflections'
require 'active_support/inflections'

module Corvid
  module Generator

    class Base < Thor
      include Thor::Actions
      RUN_BUNDLE= :'run_bundle'

      class << self
        attr_accessor :source_root

        def inherited(c)
          c.class_eval <<-EOB
            def self.source_root; ::#{self}.source_root end
            namespace ::Thor::Util.namespace_from_thor_class(self).sub(/^corvid:generator:/,'')
          EOB
        end
      end

      protected

      def rpm
        @rpm ||= Corvid::ResPatchManager.new
      end

      def with_latest_resources(&block)
        # TODO make reentrant
        rpm.with_latest_resources do |resdir|
          Corvid::Generator::Base.source_root= resdir
          return block.call
        end
      ensure
        Corvid::Generator::Base.source_root= nil
      end

      def self.run_bundle_option(t)
        t.method_option RUN_BUNDLE => true
      end

      def run_bundle
        if options[RUN_BUNDLE] and !$corvid_bundle_install_at_exit_installed
          $corvid_bundle_install_at_exit_installed= true
          at_exit{ run "bundle install" }
        end
      end

      def copy_file_unless_exists(src, tgt=nil, options={})
        tgt ||= src
        copy_file src, tgt, options unless File.exists?(tgt)
      end

      def boolean_specified_or_ask(option_name, question)
        v= options[option_name.to_sym]
        v or v.nil? && yes?(question + ' [yn]')
      end

      def copy_executable(name, *extra_args)
        copy_file name, *extra_args
        chmod name, 0755, *extra_args
      end
    end
  end
end
