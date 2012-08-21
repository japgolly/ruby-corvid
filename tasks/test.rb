namespace :test do
  def run_specs(task, dir, args=nil)
    require 'rspec/core/rake_task'
    RSpec::Core::RakeTask.new(:"test:#{task}") do |t|
      t.rspec_path= "bin/rspec"
      t.pattern= "#{dir}/{,*/,**/}*_spec.rb"
      t.verbose= false
      t.rspec_opts= args if args
    end
  end

  desc "Run fast tests."
  task :fast do
    run_specs :fast, 'test/spec', '--order random -f p -t ~slow'
  end

  desc "Run tests: specifications."
  task :spec do
    run_specs :spec, 'test/spec', '--order random'
  end

  desc "Run tests: integration."
  task :int do
    run_specs :int, 'test/integration', '--order default'
  end

end

desc "Run tests: all."
task test: %w[test:spec test:int]
