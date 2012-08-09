require 'corvid/extension'
require 'golly-utils/attr_declarative'

module Corvid
  class Feature
    include Extension

    # @!attribute [rw] since_ver
    #   The version of resources that this feature first appears in.
    #   @return [Fixnum] The version number.
    attr_declarative since_ver: 1

  end
end
