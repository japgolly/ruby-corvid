require 'corvid/plugin'
require 'corvid/extension'

class MockPlugin < Corvid::Plugin
  include Corvid::Extension

  name 'mock_plugin'

  rake_tasks {
    extend Rake::DSL

    namespace :mock do
      desc 'Generate hello.txt'
      task :hello do
        File.write 'hello.txt', 'Created by mock plugin.'
      end
    end
  }

end
