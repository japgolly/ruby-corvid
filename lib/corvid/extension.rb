require 'golly-utils/callbacks'

module Corvid
  # A class that includes this module will receive callbacks/hooks that the class author can use customise various parts
  # of Corvid's functionality.
  #
  # {Feature}s for example, include this by default.
  #
  # @example
  #   class MyExt
  #     include Corvid::Extension
  #
  #     rake_tasks {
  #       require 'my_tasks/doc.rake'
  #       require 'my_tasks/test.rake'
  #     }
  #
  # @see ExtensionRegistry
  module Extension
    include GollyUtils::Callbacks

    # TODO Find a way to get callbacks into Yard.
    define_callbacks :rake_tasks, :corvid_tasks
  end
end
