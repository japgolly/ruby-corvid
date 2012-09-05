require 'corvid/feature'

module PluginProject
  class F1Feature < Corvid::Feature

    since_ver 1

    corvid_tasks {
      require 'plugin_project/t2_task'
    }

    rake_tasks {
      extend Rake::DSL

      namespace :p1f1 do
        desc 'Generate hello.txt'
        task :hello do
          File.write 'hello.txt', 'Created by p1:f1'
        end
      end
    }

  end
end
