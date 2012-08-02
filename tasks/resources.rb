namespace :res do
  LATEST_DIR     = "#{CORVID_ROOT}/resources/latest"
  LATEST_DIR_REL = relative_to_corvid_root LATEST_DIR

  def rpm
    @rpm ||= (
      require 'corvid/res_patch_manager'
      Corvid::ResPatchManager.new
    )
  end

  def diff_latest_dir
    rpm.with_latest_resources do |dir|
      return rpm.create_res_patch_content dir, LATEST_DIR, false
    end
  end

  desc 'Create a new resource patch.'
  task :new do
    rpm.with_latest_resources do |dir|
      ver= rpm.create_res_patch_files! dir, LATEST_DIR
      puts ver ? "Created v#{ver}." : "There are no changes to record. The latest patch is up-to-date."
    end
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
        puts "Already up-to-date: #{LATEST_DIR_REL}"
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
      rpm.deploy_latest_resources(LATEST_DIR)
      puts "Deployed v#{rpm.latest_version} to #{LATEST_DIR_REL}."
    end
  end
end
