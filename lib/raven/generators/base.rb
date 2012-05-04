require 'raven/environment'

require 'thor'
require 'active_support/core_ext/string/inflections'
require 'active_support/inflections'

module Raven
  module Generator
    class Base < Thor
      include Thor::Actions

      def self.source_root
        "#{RAVEN_ROOT}/templates"
      end
      def self.inherited(c)
        c.class_eval <<-EOB
          def self.source_root; ::#{self}.source_root end
          namespace ::Thor::Util.namespace_from_thor_class(self).sub(/^raven:generator:/,'')
        EOB
      end

      protected

      def copy_file_unless_exists(src, tgt=nil, options={})
        tgt ||= src
        copy_file src, tgt, options unless File.exists?(tgt)
      end
    end
  end
end
