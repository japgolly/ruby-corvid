require 'golly-utils/singleton'
require 'golly-utils/callbacks'

module Corvid
  #---------------------------------------------------------------------------------------------------------------------

  module Extention
    include GollyUtils::Callbacks

    define_callbacks :rake_tasks
  end

  #---------------------------------------------------------------------------------------------------------------------

  class ExtentionHub
    include GollyUtils::Singleton

    def extention_providers
      @extention_providers ||= (
        # read loaded features
        # get an instance for each one
      )
    end

    # Runs all extentions for a given extention point.
    #
    # @param [Symbol] name The extention point name. Must match the callbacks declared TODO in {Extention}.
    # @return [nil]
    def extention_point(name)
      extention_providers.each do |p|
        p.run_callback name
      end
      nil
    end
  end
end
