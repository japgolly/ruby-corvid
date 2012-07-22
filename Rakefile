require 'bundler/gem_tasks'

desc "Test specifications."
task :test do
  require 'rspec/core/rake_task'
  RSpec::Core::RakeTask.new(:test) do |t|
    t.rspec_path= "bin/rspec"
    t.pattern= "test/spec{,/*,/**}/*_spec.rb"
  end
end

namespace :res do

  def setup
    require_relative 'lib/corvid/environment'
    require 'corvid/migration'
  end

  def new_m
    setup
    Migration.new res_patch_dir: "#{CORVID_ROOT}/resources"
  end

  desc 'new'
  task :new do
    m= new_m
    Dir.mktmpdir {|latest_dir|
      m.deploy_latest_res_patch(latest_dir)
      m.create_res_patch latest_dir, "#{CORVID_ROOT}/resources/latest"
    }
  end
end
