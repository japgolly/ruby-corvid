require 'corvid/extension'

module Corvid
  class Feature
    include Extension

    # The version of resources that this feature first appears in.
    #
    # @return [Fixnum] The version number.
    def since_ver
      1
    end

    # TODO resurrect attr_declarative?
    def self.since_ver(ver)
      raise "Invalid version: #{ver}" unless ver.is_a?(Fixnum) && ver > 0
      class_eval "def since_ver; #{ver}; end"
    end

  end
end
