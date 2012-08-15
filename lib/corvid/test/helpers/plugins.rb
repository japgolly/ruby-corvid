module Corvid
  module PluginTestHelpers

    def generator_config(quiet)
      # Quiet stdout - how the hell else are you supposed to do this???
      config= {}
      config[:shell] ||= Thor::Base.shell.new
      if quiet
        config[:shell].instance_eval 'def say(*) end'
        config[:shell].instance_eval 'def quiet?; true; end'
        #config[:shell].instance_variable_set :@mute, true
      end
      config
    end

    def quiet_generator(generator_class, cli_args=[])
      config= generator_config(true)
      g= generator_class.new(cli_args, [], config)
      decorate_generator g
    end

    def decorate_generator(g)
      # Use a test res-patch manager if available
      g.instance_variable_set :@rpms, @rpms if @rpms
      g
    end

  end
end
