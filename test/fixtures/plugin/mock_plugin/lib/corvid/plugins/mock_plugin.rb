require 'corvid/plugin'

class MockPlugin < Corvid::Plugin

  rake_tasks do
    extend Rake::DSL

    namespace :mock do
      desc 'Generate hello.txt'
      task :hello do
        File.write 'hello.txt', 'Created by mock plugin.'
      end
    end

  end

end
