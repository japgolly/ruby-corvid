require 'corvid/extension'
require 'golly-utils/attr_declarative'

module Corvid
  class Feature
    include Extension

    # @!attribute [rw] since_ver
    #
    #   The version of resources that this feature first appears in.
    #
    #   @return [Fixnum] The version number.
    attr_declarative since_ver: 1

    # @!attribute [rw] requirements
    #
    #   Requirements that must be satisfied before the feature can be installed.
    #
    #   @return [nil, String, Hash<String,Fixnum|Range|Array<Fixnum>>, Array] Requirements that can be provided to
    #     {RequirementValidator}.
    #   @see RequirementValidator#add
    attr_declarative :requirements

    # @!attribute [rw] managed_install_task?
    #
    #   Indicates whether or not Corvid should automatically manage the creation and exposure of an install task for
    #   this feature.
    #
    #   If a client has this plugin installed but not this feature, when this attribute is `true`, Corvid CLI will
    #   automatically generate and provide a task to install this feature.
    #
    #   Defaults to `true`.
    #
    #   @return [Boolean]
    attr_declarative managed_install_task?: true

  end
end
