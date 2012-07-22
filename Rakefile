require 'bundler/gem_tasks'
CORVID_ROOT= File.expand_path '..', __FILE__

desc "Test specifications."
task :test do
  require 'rspec/core/rake_task'
  RSpec::Core::RakeTask.new(:test) do |t|
    t.rspec_path= "bin/rspec"
    t.pattern= "test/spec{,/*,/**}/*_spec.rb"
  end
end

namespace :res do
  RES_PATCH_DIR= "#{CORVID_ROOT}/resources"
  LATEST_DIR= "#{CORVID_ROOT}/resources/latest"

  def setup
    require_relative 'lib/corvid/environment'
    require 'corvid/migration'
  end

  def new_m
    setup
    Migration.new res_patch_dir: RES_PATCH_DIR
  end

  desc 'Create a new resource patch.'
  task :new do
    m= new_m
    Dir.mktmpdir {|latest_dir|
      m.deploy_latest_res_patch(latest_dir)
      m.create_res_patch latest_dir, LATEST_DIR
    }
  end

  desc "Shows the differences between the latest resource patch and #{LATEST_DIR.sub! CORVID_ROOT+'/', ''}."
  task :diff do
    m= new_m
    Dir.mktmpdir {|latest_dir|
      m.deploy_latest_res_patch(latest_dir)
      patch= m.generate_single_res_patch latest_dir, LATEST_DIR, false
      puts patch ? patch : "No differences."
    }
  end

end
