require 'corvid/extension'
require 'golly-utils/attr_declarative'

module Corvid
  # Corvid plugins can have features. Features are used by plugins to allow the selective installation of differing
  # chunks of functionality. A plugin might make 3 different features available, and allow the user to install and use
  # only 1. Or 2. Or none or all 3.
  #
  # Features require:
  #
  # * A feature-installer file in the plugin resources.
  # * An entry in the plugin's feature manifest.
  #
  # When generating a new feature in a Corvid plugin project, both points above will be performed for you automatically.
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
