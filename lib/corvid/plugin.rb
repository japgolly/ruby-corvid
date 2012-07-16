require 'golly-utils/callbacks'
require 'golly-utils/ruby_ext/subclasses'

module Corvid
  class Plugin
    include GollyUtils::Callbacks

    define_callbacks :rake_tasks

  end
end
