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

  desc 'Recreate the latest resource patch (USE WITH CARE)'
  task :redo do
    puts "WARNING: If the latest resource patch has been released, then recreating it rather than creating a new patch will cause all clients to miss any changes you've just made."
    puts "Only use this feature for development and testing, and if the latest resource patch hasn't been deployed yet."
    puts

    latest= rpm.latest_version
    unless latest >= 1
      raise "No resources patches found. Use res:new instead."
    end

    puts "Recreating v#{latest}..."
    rpm.with_resources latest-1 do |dir|
      # Move latest somewhere else
      redone_cur= rpm.res_patch_filename(latest)
      redone_new= "%s/%05d-redone-%s.patch" % [Dir.tmpdir, latest, Time.new.strftime('%Y%m%d%H%M%S')]
      puts "Moving #{redone_cur} to #{redone_new}"
      FileUtils.mv redone_cur, redone_new
      rpm.latest_version true

      # Create new version
      ver= rpm.create_res_patch_files! dir, LATEST_DIR
      puts ver ? "Recreated v#{ver}." : "There are no changes to record. The latest patch is now v#{rpm.latest_version}.\nYou might need to run this again actually (yes, right now). This scenario is as-yet untested."
    end
  end

  desc "Shows the differences between the latest resource patch and #{LATEST_DIR_REL}."
  task :diff do
    if Dir.exists?(LATEST_DIR)
      patch= diff_latest_dir
      if !patch
        puts "No differences."
      elsif STDOUT.tty? and (`colordiff --help` rescue nil; $?.success?)
        require 'tempfile'
        Tempfile.open('res_diff') do |f|
          f.write patch
          f.close
          system "cat #{f.path.inspect} | colordiff"
        end
      else
        puts patch
      end
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
