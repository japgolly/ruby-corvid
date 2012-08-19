require 'corvid/extension'
require 'golly-utils/attr_declarative'

module Corvid
  class Feature
    include Extension

    # @!attribute [rw] since_ver
    #   The version of resources that this feature first appears in.
    #   @return [Fixnum] The version number.
    attr_declarative since_ver: 1

    # @!attribute [rw] requirements
    #   Requirements that must be satisfied before the feature can be installed.
    #   @return [nil, String, Hash<String,Fixnum|Range|Array<Fixnum>>, Array] Requirements that can be provided to
    #     {RequirementValidator}.
    #   @see RequirementValidator#add
    attr_declarative :requirements

  end
end
