module Corvid
  module Constants
    # The current version of Corvid. (Nothing to do with resource versions.)
    VERSION = "0.0.1"

    # Filename of the client-side file that stores the version of Corvid resources last deployed.
    VERSIONS_FILE = '.corvid/versions.yml'

    # Filename of the client-side file that stores the Corvid features that are enabled in the client's project.
    FEATURES_FILE = '.corvid/features.yml'

    # Filename of the client-side file that stores the Corvid plugins that are enabled in the client's project.
    PLUGINS_FILE = '.corvid/plugins.yml'

    # Freeze all constants
    constants.each {|c| const_get(c).freeze }
  end
end

