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

    # @!group Extension Points (Callbacks)

    # @!parse
    #   # Invoked when a client project starts up Rake. Allows additional Rake tasks to be loaded.
    #   #
    #   # @yield Require Rake tasks in this callback.
    #   # @return [void]
    #   def rake_tasks; end
    define_callback :rake_tasks

    # @!parse
    #   # Invoked when Corvid CLI starts up in a client project. Allows additional Corvid tasks to be loaded.
    #   #
    #   # @yield Require Corvid tasks in this callback.
    #   # @return [void]
    #   def corvid_tasks; end
    define_callback :corvid_tasks

  end
end
