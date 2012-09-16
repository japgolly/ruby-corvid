require_relative 'all'

module TestHelpers

  def run_generator(generator_class, args, no_bundle=true, quiet=true)
    args= args.split(/\s+/) unless args.is_a?(Array)
    args<< "--no-#{RUN_BUNDLE}" if no_bundle

    config= generator_config(quiet)

    # Do horrible stupid Thor-internal crap to instantiate a generator
    task= generator_class.tasks[args.shift]
    args, opts = Thor::Options.split(args)
    config.merge!(:current_task => task, :task_options => task.options)
    g= generator_class.new(args, opts, config)

    decorate_generator g
    g.invoke_task task
  end

  def mock_new(klass, real=false)
    instance= case real
              when false then mock "Mock #{klass}"
              when true  then klass.new
              else real
              end
    klass.should_receive(:new).and_return(instance)
    instance
  end

  module ClassMethods

    def add_generator_lets
      class_eval <<-EOB
        let(:fr){ Corvid::FeatureRegistry.send :new }
        let(:pr){ Corvid::PluginRegistry.send :new }
        let(:subject){
          g= quiet_generator(described_class)
          g.plugin_registry= pr
          g.feature_registry= fr
          g.stub :say
          g
        }
        def mock_client_state(plugins, features, versions)
          pr     .should_receive(:read_client_plugins ).at_least(:once).and_return plugins
          fr     .should_receive(:read_client_features).at_least(:once).and_return features
          subject.should_receive(:read_client_versions).at_least(:once).and_return versions
        end
        def stub_client_state(plugins, features, versions)
          pr.stub      read_client_plugins:   plugins
          fr.stub      read_client_features:  features
          subject.stub read_client_versions:  versions
        end
      EOB
    end

  end
end
