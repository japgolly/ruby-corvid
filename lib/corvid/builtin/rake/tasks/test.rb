corvid_test_tasks= []

namespace :test do

  # test:unit
  if Dir.exists?("#{APP_ROOT}/test/unit")
    desc "Run unit tests."
    task :unit do
      require 'rake/testtask'
      Rake::TestTask.new(:'test:unit') do |t|
        t.pattern= "#{APP_ROOT}/test/unit{,/*,/**}/*_test.rb"
        t.verbose= false
      end
    end
    corvid_test_tasks<< 'test:unit'
  end

  # test:spec
  if Dir.exists?("#{APP_ROOT}/test/spec")
    desc "Test specifications."
    task :spec do
      require 'rspec/core/rake_task'
      RSpec::Core::RakeTask.new(:'test:spec') do |t|
        t.rspec_path= "#{APP_ROOT}/bin/rspec"
        t.pattern= "#{APP_ROOT}/test/spec{,/*,/**}/*_spec.rb"
        t.verbose= false
      end
    end
    corvid_test_tasks<< 'test:spec'
  end

end

# test
unless corvid_test_tasks.empty?
  desc 'Run all tests.'
  task test: corvid_test_tasks
end

