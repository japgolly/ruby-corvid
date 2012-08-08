require 'golly-utils/callbacks'

module Corvid
  module Extension
    include GollyUtils::Callbacks

    # TODO Find a way to get callbacks into Yard.
    define_callbacks :rake_tasks
  end
end
