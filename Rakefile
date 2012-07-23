require 'bundler/gem_tasks'
CORVID_ROOT= File.expand_path '..', __FILE__
$:<< "#{CORVID_ROOT}/lib"

def relative_to_corvid_root(dir)
  dir.sub /^#{Regexp.quote CORVID_ROOT}[\\\/]+/, ''
end

desc "Test specifications."
task :test do
  require 'rspec/core/rake_task'
  RSpec::Core::RakeTask.new(:test) do |t|
    t.rspec_path= "bin/rspec"
    t.pattern= "test/spec{,/*,/**}/*_spec.rb"
  end
end

namespace :res do
  RES_PATCH_DIR  = "#{CORVID_ROOT}/resources"
  LATEST_DIR     = "#{CORVID_ROOT}/resources/latest"
  LATEST_DIR_REL = relative_to_corvid_root LATEST_DIR

  def setup
    require_relative 'lib/corvid/environment'
    require 'corvid/migration'
  end

  def new_m
    setup
    Migration.new res_patch_dir: RES_PATCH_DIR
  end

  def diff_latest_dir
    m= new_m
    Dir.mktmpdir {|tmpdir|
      m.deploy_latest_res_patch(tmpdir)
      return m.generate_single_res_patch tmpdir, LATEST_DIR, false
    }
  end

  desc 'Create a new resource patch.'
  task :new do
    m= new_m
    Dir.mktmpdir {|latest_dir|
      m.deploy_latest_res_patch(latest_dir)
      m.create_res_patch latest_dir, LATEST_DIR
    }
  end

  desc "Shows the differences between the latest resource patch and #{LATEST_DIR_REL}."
  task :diff do
    if Dir.exists?(LATEST_DIR)
      patch= diff_latest_dir
      puts patch ? patch : "No differences."
    else
      puts "Directory doesn't exist: #{LATEST_DIR_REL}"
    end
  end

  desc "Deploys the latest version of resources into #{LATEST_DIR_REL}."
  task :latest do
    require 'corvid/rake/prompt'
    deploy= true

    # Check if already populated
    if Dir.exists?(LATEST_DIR) and not (Dir.entries(LATEST_DIR) - %w[. ..]).empty?

      # Check if already up-to-date
      if diff_latest_dir().nil?
        puts "Already up-to-date."
        deploy= false
      else
        # Ask to overwrite
        unless prompt "#{LATEST_DIR_REL} already exists and contains unpackaged changes.\nWould you like to replace it?"
          STDERR.puts "Aborting."
          exit 0
        end

        # Move existing to /tmp
        new_dir= "#{Dir.tmpdir}/corvid-resources-#{Time.new.strftime '%Y%m%d%H%M%S'}"
        FileUtils.mv LATEST_DIR, new_dir
        STDERR.puts "Moved contents of #{LATEST_DIR_REL} to #{new_dir}"
      end
    end

    if deploy
      # Create directory
      require 'fileutils'
      FileUtils.mkdir_p LATEST_DIR

      # Deploy latest
      m= new_m
      m.deploy_latest_res_patch(LATEST_DIR)
      puts "Deployed v#{m.get_latest_res_patch_version}."
    end
  end
end
