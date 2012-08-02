desc "Test specifications."
task :test do
  require 'rspec/core/rake_task'
  RSpec::Core::RakeTask.new(:test) do |t|
    t.rspec_path= "bin/rspec"
    t.pattern= "test/spec{,/*,/**}/*_spec.rb"
  end
end

