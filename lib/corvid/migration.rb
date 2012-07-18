require 'fileutils'
require 'tempfile'
require 'digest/sha2'

class Migration
  DIGEST= Digest::SHA2

  def migrate(options)
    from_ver = options[:from] || 0
    to_ver = options[:to]
    mig_dir = options[:migration_dir]
    tgt_dir = Dir.pwd

    raise if from_ver < 0
    raise if to_ver < from_ver
    raise unless Dir.exists?(mig_dir)

    # Build list of files
    filelist= {}
    for v in from_ver..to_ver do
      unless v == 0
        src_dir= '%s/ver_%03d' % [mig_dir,v]
        raise unless Dir.exists?(src_dir)
        Dir.chdir src_dir do
          Dir.glob("**/*", File::FNM_DOTMATCH).each do |f|
            if File.file?(f)
              filelist[f] ||= {}
            end
          end
        end
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
          vf= "#{upgrade_dir ver}/#{f}"
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
      from_file,to_file = [from_ver2,to_ver]
        .map{|ver| "#{upgrade_dir ver}/#{f}" }
        .map{|f| File.exists?(f) ? f : '/dev/null'}
      patch= `diff -u #{from_file.inspect} #{to_file.inspect} 2>/dev/null`
      case $?.exitstatus
      when 0
        # No differences
      when 1
        # Differences found
        patchlines= patch.split($/)
        patchlines[0].sub! /^\-\-\- .+?(?=\t)/, "--- #{f}"
        patchlines[1].sub! /^\+\+\+ .+?(?=\t)/, "+++ #{f}"
        patch= patchlines.join($/)
        patches[f]= patch
      else
        raise "Diff failed. #$?"
      end
    end

    # Apply patches
    unless patches.empty?
      megapatch= patches.values.join($/) + $/
#puts '_'*80; puts megapatch; puts '_'*80
      tmp= Tempfile.new('corvid-migration')
      begin
        tmp.write megapatch
        tmp.close
        `patch -p0 -ui #{tmp.path.inspect}`
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

  # TODO rename and stop being hardcoded
  def upgrade_dir(ver=nil)
    d= "#{CORVID_ROOT}/test/fixtures/upgrades"
    d+= '/ver_%03d' % [ver] if ver
    d
  end

end
