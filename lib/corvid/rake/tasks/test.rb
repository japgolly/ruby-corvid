corvid_test_tasks= []

namespace :test do

  # test:unit
  if Dir.exists?("#{APP_ROOT}/test/unit")
    desc "Run unit tests."
    task :unit do
      require 'rake/testtask'
      Rake::TestTask.new(:'test:unit') do |t|
        t.pattern= "#{APP_ROOT}/test/unit{,/*,/**}/*_test.rb"
        t.verbose= true
      end
    end
    corvid_test_tasks<< 'test:unit'
  end

end

# test
unless corvid_test_tasks.empty?
  desc 'Run all tests.'
  task test: corvid_test_tasks
end

