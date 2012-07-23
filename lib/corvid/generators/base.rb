require 'corvid/environment'

require 'thor'
require 'active_support/core_ext/string/inflections'
require 'active_support/inflections'

module Corvid
  module Generator

    class Base < Thor
      include Thor::Actions
      RUN_BUNDLE= :'run_bundle'

      def self.source_root
        "#{CORVID_ROOT}/templates"
      end
      def self.inherited(c)
        c.class_eval <<-EOB
          def self.source_root; ::#{self}.source_root end
          namespace ::Thor::Util.namespace_from_thor_class(self).sub(/^corvid:generator:/,'')
        EOB
      end

      protected

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
