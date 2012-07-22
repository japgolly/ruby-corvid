require 'fileutils'
require 'tempfile'
require 'tmpdir'
require 'digest/sha2'

class Migration

  # The directory where resource patches are located.
  attr_accessor :res_patch_dir

  def initialize(options={})
    options.each{|k,v| public_send :"#{k}=", v }
  end

  def create_res_patch(options)
    from_dir = options[:from]
    to_dir = options[:to]

    raise unless Dir.exists?(from_dir)
    raise unless Dir.exists?(to_dir)
    raise unless Dir.exists?(res_patch_dir)

    content_backwards= generate_single_res_patch to_dir, from_dir
    return nil unless content_backwards
    content_new= generate_single_res_patch nil, to_dir

    prev_ver= get_latest_res_patch_version
    prev_pkg= prev_ver == 0 ? nil : res_patch_filename(prev_ver)
    this_ver= prev_ver + 1
    this_pkg= res_patch_filename(this_ver)

    File.write prev_pkg, content_backwards if prev_pkg # TODO encoding
    File.write this_pkg, content_new # TODO encoding

    true
  end

  # Deploys the latest version of resources to an empty directory.
  #
  # @param [String] target_dir The directory where the resources should be deployed to. If it doesn't exist, it will be
  #   created. If it exists, it must be empty.
  def deploy_latest_res_patch(target_dir)
    Dir.mkdir target_dir unless Dir.exists?(target_dir)
    raise "Target directory must be empty." unless get_files_in_dir(target_dir).empty?

    # Deploy
    latest_version= get_latest_res_patch_version
    apply_res_patch target_dir, latest_version if latest_version != 0

    true
  end

  def deploy_res_patches(target_dir, target_version=nil, from_version=nil)
    latest_version= get_latest_res_patch_version
    target_version ||= latest_version
    from_version ||= 0
    return if target_version == 0 and latest_version == 0 and from_version == 0
    #puts "Deploying ver #{target_version}..."
    raise unless target_version > 0 and target_version <= latest_version
    raise unless from_version  >= 0 and from_version   <= target_version
    return if from_version == target_version

    # Explode each ver into its own directory
    with_reconstruction_dir do |reconstruction_base_dir|
      last_dir= nil
      last_dir_digest= digest_dir(reconstruction_base_dir) # it contains no files

      # Iterate over versions...
      latest_version.downto(from_version + 1) do |ver|
        this_dir= reconstruction_dir(ver)
        Dir.mkdir this_dir

        # Apply res patch for this version
        new_dir_digest= apply_res_patch this_dir, ver, last_dir_digest, last_dir

        last_dir= this_dir
        last_dir_digest= new_dir_digest
      end

      # Migrate
      migrate from_version, target_version, target_dir
    end

    true
  end

  protected

  # @param [nil,String] dir
  def get_files_in_dir(dir)
    r= []
    Dir.chdir dir do
      Dir.glob("**/*", File::FNM_DOTMATCH).sort.each do |f|
        if File.file?(f)
          f= yield f if block_given?
          r<< f
        end
      end
    end if dir
    r
  end

  def migrate(from_ver, to_ver, target_dir)
    from_ver ||= 0
    raise unless from_ver >= 0
    raise unless to_ver >= from_ver
    return if from_ver == to_ver

    # Build list of files
    filelist= {}
    for v in from_ver..to_ver do
      next if v == 0
      src_dir= reconstruction_dir(v)
      raise unless Dir.exists?(src_dir)
      get_files_in_dir(src_dir){|f| filelist[f] ||= {} }
    end

    # Create patches
    patches= {}
    Dir.chdir target_dir do
      filelist.each do |f,fv|
        from_ver2= from_ver

        # Check if deployed is identical to a versioned copy
        if File.exists?(f)
          csum= DIGEST.file(f)
          to_ver.downto(from_ver) do |ver|
            vf= "#{reconstruction_dir ver}/#{f}"
            if File.exists?(vf) and csum == DIGEST.file(vf)
              # Found a match
              from_ver2= ver
              break
            end
          end
        end

        # Do nothing if target is already up-to-date
        next if from_ver2 == to_ver

        # Create patch
        from_file,to_file = [from_ver2,to_ver].map{|ver| "#{reconstruction_dir ver}/#{f}" }
        patch= create_patch f, from_file, to_file
        patches[f]= patch if patch
      end
    end

    # Apply patches
    unless patches.empty?
      megapatch= patches.values.join($/) + $/
#puts '_'*80; puts megapatch; puts '_'*80
      apply_patch target_dir, megapatch
    end

  end

  # @param [String] relative_filename
  # @param [nil,String] from_file
  # @param [nil,String] to_file
  def create_patch(relative_filename, from_file, to_file)
    from_file= '/dev/null' unless from_file and File.exists? from_file
    to_file= '/dev/null' unless to_file and File.exists? to_file
    patch= `diff -u #{from_file.inspect} #{to_file.inspect} 2>/dev/null`
    case $?.exitstatus
    when 0
      # No differences
      nil
    when 1
      # Differences found
      patchlines= patch.split($/)
      correct_filename_in_patchline! patchlines[0], relative_filename
      correct_filename_in_patchline! patchlines[1], relative_filename
      patch= patchlines.join($/)
    else
      raise "Diff failed. #$?"
    end
  end

  def apply_patch(target_dir, patch)
    Dir.chdir target_dir do
      tmp= Tempfile.new('corvid-migration')
      begin
        tmp.write patch
        tmp.close
        `patch -p0 -u -i #{tmp.path.inspect} --no-backup-if-mismatch`
        # patch's  exit  status  is  0 if all hunks are applied successfully, 1 if some
        # hunks cannot be applied or there were merge conflicts, and 2 if there is more
        # serious trouble.  When applying a set of patches in a loop it behooves you to
        # check this exit status so you don't  apply  a  later  patch  to  a  partially
        # patched file.
        # TODO No patch error or conflict handling
        raise "Patch failed!" unless $?.success?
      ensure
        tmp.close
        tmp.delete
      end
    end
  end

  def res_patch_filename(ver)
    '%s/%05d.patch' % [res_patch_dir,ver]
  end

  def get_latest_res_patch_version
    prev_pkg= Dir["#{res_patch_dir}/[0-9][0-9][0-9][0-9][0-9].patch"].sort.last
    prev_ver= prev_pkg ? prev_pkg.sub(/\D+/,'').to_i : 0
  end

  # @param [nil,String] dir
  # @return String
  def digest_dir(dir)
    digests= get_files_in_dir(dir){|f| DIGEST.file f}
    DIGEST.hexdigest digests.join(nil)
  end

  def read_digest_from_res_patch_header(header_lines, title)
    v= header_lines.map{|l| l =~ /^#{title}:\s+([0-9a-f]+)\s*$/; $1 ? $1.dup : nil }.compact.first
    v || raise("Checksum '#{title}' not found in patch header.")
  end

  # @param [nil,String] from_dir
  # @param [String] to_dir
  # @return String
  def generate_single_res_patch(from_dir, to_dir)
    files= get_files_in_dir(from_dir) | get_files_in_dir(to_dir)
    patch= files.sort
             .map{|f| create_patch f, from_dir ? "#{from_dir}/#{f}" : nil, "#{to_dir}/#{f}" }
             .join("\n") + "\n"
    return nil if patch.empty?

    from_digest= digest_dir(from_dir)
    to_digest= digest_dir(to_dir)
    patch_digest= DIGEST.hexdigest(patch)
    header= "Before: #{from_digest}\nAfter: #{to_digest}\nPatch: #{patch_digest}\n"

    header + patch
  end

  # Will check the patch checksum and raise an error if not correct.
  #
  # @return [Hash] with keys `:patch`, `:digest_before`, `:digest_after`
  def read_res_patch(ver_or_filename)
    filename= if ver_or_filename.is_a?(Fixnum)
                res_patch_filename ver_or_filename
              else
                ver_or_filename
              end
    r= {}

    # Read migration patch
    pkg= File.read filename # TODO encoding
    pkg= pkg.split("\n")
    header= pkg[0..2]
    r[:patch]= pkg[3..-1].join("\n") + "\n"
    r[:digest_before]= read_digest_from_res_patch_header header, 'Before'
    r[:digest_after] = read_digest_from_res_patch_header header, 'After'
    r[:digest_patch] = read_digest_from_res_patch_header header, 'Patch'

    # Check patch-checksum
    x= DIGEST.hexdigest r[:patch]
    if r[:digest_patch] != x
      raise "Resource patch #{filename} is invalid. The expected patch checksum is #{r[:digest_patch]} but the file's is #{x}."
    end

    r
  end

  # Deploys a specific version of resources.
  #
  # @param [String] target_dir The directory where the resources will be deployed to. Must exist.
  # @param [Fixnum] ver The version of resources to deploy.
  # @param [nil,String] digest_before The hex digest of the contents of the previous directory. This will be compared to the
  #   *before* checksum in the resource patch before applying. If `nil` then a digest will be calculated for the target
  #   directory before applying the patch.
  # @param [nil,String] prev_ver_dir The directory containing the already-deployed contents of this target version + 1. If
  #   provided then the contents of the directory will be copied to `target_dir` before applying the patch.
  def apply_res_patch(target_dir, ver, digest_before=nil, prev_ver_dir=nil)

    # Read migration patch
    patch_data= read_res_patch(ver)

    # Copy previous version into target directory
    FileUtils.cp_r "#{prev_ver_dir}/.", target_dir if prev_ver_dir

    # Check before-checksum
    digest_before ||= digest_dir(target_dir)
    if patch_data[:digest_before] != digest_before
      errmsg= "Cannot apply res-patch ##{ver} to #{target_dir}. Its contents do not match those that the patch expects to be applied to."
      errmsg+= " Ensure that the 'after' checksum of res-patch ##{ver+1} matches the 'before' checksum of #{ver}." unless ver == get_latest_res_patch_version
      raise errmsg
    end

    # Reconstruct current version
    apply_patch target_dir, patch_data[:patch]

    # Check after-checksum
    new_dir_digest= digest_dir(target_dir)
    if patch_data[:digest_after] != new_dir_digest
      raise "After successfully creating patch ver ##{ver}, the contents don't seem to match what was expected."
    end

    new_dir_digest
  end

  private
  DIGEST= Digest::SHA2

  def with_reconstruction_dir(dir=nil, &block)
    if dir.nil?
      Dir.mktmpdir {|d| with_reconstruction_dir d, &block }
    else
      raise "Invalid reconstruction dir; it doesn't exist: #{dir}" unless Dir.exists?(dir)
      begin
        @reconstruction_dir= dir
        block.call dir
      ensure
        @reconstruction_dir= nil
      end
    end
  end

  def reconstruction_dir(ver)
    raise "Call with_reconstruction_dir() first." unless @reconstruction_dir
    "#{@reconstruction_dir}/#{ver}"
  end

  def correct_filename_in_patchline!(line, filename)
    return line if %r!^(?:-{3}|\+{3})\s+?/dev/null\t! === line
    line.sub! /(?<=^(?:-{3}|\+{3})\s).+?(?=\t)/, filename
  end
end
