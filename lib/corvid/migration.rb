require 'fileutils'
require 'tempfile'
require 'tmpdir'
require 'digest/sha2'

class Migration
  DIGEST= Digest::SHA2

  attr_accessor :migration_dir

  def initialize(options={})
    options.each{|k,v| public_send :"#{k}=", v }
  end

  def migrate(options)
    from_ver = options[:from] || 0
    to_ver = options[:to]
    ver_dir = options[:ver_dir] || @ver_dir
    @ver_dir= ver_dir
    tgt_dir = Dir.pwd

    raise if from_ver < 0
    raise if to_ver < from_ver
    raise unless Dir.exists?(ver_dir)

    # Build list of files
    filelist= {}
    for v in from_ver..to_ver do
      unless v == 0
        src_dir= ver_dir(v)
        raise unless Dir.exists?(src_dir)
        get_files_in_dir(src_dir){|f| filelist[f] ||= {} }
      end
    end

    # Create patches
    patches= {}
    filelist.each do |f,fv|
      from_ver2= from_ver

      # Check if deployed is identical to a versioned copy
      if File.exists?(f)
        csum= DIGEST.file(f)
        to_ver.downto(from_ver) do |ver|
          vf= "#{ver_dir ver}/#{f}"
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
      from_file,to_file = [from_ver2,to_ver].map{|ver| "#{ver_dir ver}/#{f}" }
      patch= create_patch f, from_file, to_file
      patches[f]= patch if patch
    end

    # Apply patches
    unless patches.empty?
      megapatch= patches.values.join($/) + $/
#puts '_'*80; puts megapatch; puts '_'*80
      apply_patch megapatch
    end

  end

  def create_pkg_file(options)
    from_dir = options[:from]
    to_dir = options[:to]

    raise unless Dir.exists?(from_dir)
    raise unless Dir.exists?(to_dir)
    raise unless Dir.exists?(migration_dir)

    content= create_pkg_content from_dir, to_dir
    return nil unless content

    prev_ver= get_latest_migration_version migration_dir
    this_ver= prev_ver + 1
    this_pkg= migration_file this_ver

    File.write this_pkg, content # TODO encoding
    this_pkg
  end

  def create_pkg_content(from_dir, to_dir)
    files= get_files_in_dir(from_dir) | get_files_in_dir(to_dir)
    patch= files.sort
             .map{|f| create_patch f, "#{from_dir}/#{f}", "#{to_dir}/#{f}" }
             .join("\n") + "\n"
    return nil if patch.empty?

    from_digest= digest_dir(from_dir)
    to_digest= digest_dir(to_dir)
    patch_digest= DIGEST.hexdigest(patch)
    header= "Before: #{from_digest}\nAfter: #{to_digest}\nPatch: #{patch_digest}\n"

    header + patch
  end

  def deploy_pkg_file(target_dir, version=nil)
    version ||= get_latest_migration_version migration_dir
    puts "Deploying ver #{version}..."
    raise if version < 0
    return if version == 0

    # Explode each ver into its own directory
    Dir.mktmpdir do |ver_dir|
      @ver_dir= ver_dir

      Dir.mkdir ver_dir(0)

      1.upto(version) do |ver|
        Dir.mkdir ver_dir(ver)

        # Read migration patch
        pkg= File.read migration_file(ver) # TODO encoding
        pkg= pkg.split("\n")
        header= pkg[0..2]
        patch= pkg[3..-1].join("\n") + "\n"
        from_digest= read_digest_from_pkg_header header, 'Before'
        to_digest= read_digest_from_pkg_header header, 'After'
        patch_digest= read_digest_from_pkg_header header, 'Patch'

        # Check checksums
        x= DIGEST.hexdigest patch
        if patch_digest != x
          raise "Patch ##{ver} is invalid. The expected patch checksum is #{patch_digest} but the current file's is #{x}."
        end
        x= digest_dir ver_dir(ver-1)
        if from_digest != x
          raise "These seems to be a mismatch between patch ver ##{ver-1}, and the parent/base ver of ###{ver}."
        end

        # Crete new version
        Dir.chdir ver_dir(ver) do
          FileUtils.cp_r ver_dir(ver-1)+'/.', '.'
          apply_patch patch
        end

        # Check we get what we expected
        x= digest_dir ver_dir(ver)
        if to_digest != x
          raise "After successfully creating patch ver ##{ver}, the contents don't seem to match what was expected."
        end
      end

      # Migrate
      Dir.chdir(target_dir) do
        migrate from: 0, to: version
      end
    end
  end

  protected

  def get_files_in_dir(dir)
    r= []
    Dir.chdir dir do
      Dir.glob("**/*", File::FNM_DOTMATCH).sort.each do |f|
        if File.file?(f)
          f= yield f if block_given?
          r<< f
        end
      end
    end
    r
  end

  def create_patch(relative_filename, from_file, to_file)
    from_file= '/dev/null' unless File.exists? from_file
    to_file= '/dev/null' unless File.exists? to_file
    patch= `diff -u #{from_file.inspect} #{to_file.inspect} 2>/dev/null`
    case $?.exitstatus
    when 0
      # No differences
      nil
    when 1
      # Differences found
      patchlines= patch.split($/)
      replace_filename_in_patchline! patchlines[0], relative_filename
      replace_filename_in_patchline! patchlines[1], relative_filename
      patch= patchlines.join($/)
    else
      raise "Diff failed. #$?"
    end
  end

  def apply_patch(patch)
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

  def migration_file(ver)
    '%s/%05d.patch' % [migration_dir,ver]
  end

  def get_latest_migration_version(migration_dir)
    prev_pkg= Dir["#{migration_dir}/[0-9][0-9][0-9][0-9][0-9].patch"].sort.last
    prev_ver= prev_pkg ? prev_pkg.sub(/\D+/,'').to_i : 0
  end

  def digest_dir(dir)
    digests= get_files_in_dir(dir){|f| DIGEST.file f}
    DIGEST.hexdigest digests.join(nil) + '34'
  end

  def read_digest_from_pkg_header(header_lines, title)
    v= header_lines.map{|l| l =~ /^#{title}:\s+([0-9a-f]+)\s*$/; $1 ? $1.dup : nil }.compact.first
    v || raise("Checksum '#{title}' not found in patch header.")
  end

  private

  def ver_dir(ver)
    "#{@ver_dir}/#{ver}"
  end

  def replace_filename_in_patchline!(line, filename)
    return line if %r!^(?:-{3}|\+{3})\s+?/dev/null\t! === line
    line.sub! /(?<=^(?:-{3}|\+{3})\s).+?(?=\t)/, filename
  end
end
