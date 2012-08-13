require 'fileutils'
require 'tempfile'
require 'tmpdir'
require 'digest/sha2'

module Corvid

  # Manages the generation, deployment, and patch-migration of versioned resources.
  class ResPatchManager

    # Returns the default directory that res-patches are expected to reside in.
    # @return [String]
    def self.default_res_patch_dir
      require 'corvid/environment' unless defined?(CORVID_ROOT)
      res_patch_dir= "#{CORVID_ROOT}/resources"
    end

    # The directory where resource patches are located.
    # @return [String]
    attr_reader :res_patch_dir

    # The command to run `diff`.
    # @return [String]
    attr_accessor :diff_exe

    # The command to run `patch`.
    # @return [String]
    attr_accessor :patch_exe

    def initialize(res_patch_dir = self.class.default_res_patch_dir)
      self.res_patch_dir= res_patch_dir
      self.diff_exe= 'diff'
      self.patch_exe= 'patch'
    end

    def res_patch_dir=(res_patch_dir)
      @latest_version= nil
      @res_patch_dir= res_patch_dir
    end

    # Inspects the {#res_patch_dir} to determine the latest version of resources.
    #
    # @param [Boolean] force If `true` then a cached value will be discarded and the latest version reevaluated.
    # @return [Fixnum] The latest version, or 0 if there are no res-patches.
    def latest_version(force=false)
      @latest_version= nil if force
      @latest_version ||= \
        if prev_pkg= Dir["#{res_patch_dir}/[0-9][0-9][0-9][0-9][0-9].patch"].sort.last
          File.basename(prev_pkg).sub(/\D+/,'').to_i
        else
          0
        end
    end

    # Checks if a given version is the latest.
    #
    # @param [Fixnum] version The version to test.
    # @return [Boolean]
    def latest?(version)
      version == latest_version
    end

    # Checks that a given version is valid.
    #
    # @param [Fixnum] ver The version to check.
    # @param [Fixnum] min The minimum acceptable version (inclusive). 0 is also acceptable.
    # @param [nil,String] name The name of the variable being checked. Used in error messages.
    #   eg. `"upgrade target version"`
    # @return [true]
    # @raise If given version is not a valid number.
    # @raise If given version is beyond the latest available version.
    # @raise If given minimum is beyond the latest available version.
    # @raise If given version is below the provided minimum.
    def validate_version!(ver, min, name=nil)
      def invalid_msg; "Invalid version" + name ? " for #{name}" : ''; end

      unless ver.is_a?(Fixnum)
        raise "#{invalid_msg}. #{ver.inspect} is not a valid integer."
      end
      if min > latest_version
        raise "Something's not right, the minimum required version for #{name} is #{min} but the latest available is #{latest_version}."
      end
      unless ver >= min and ver <= latest_version
        raise "#{invalid_msg}. #{name} must be between #{min} and #{latest_version} (inclusive)."
      end
      true
    end

    # Generates a res-patch in-memory. (Doesn't save anything.)
    #
    # @param [nil,String] from_dir
    # @param [String] to_dir
    # @return String The patch contents.
    def create_res_patch_content(from_dir, to_dir, include_header=true)
      files= get_files_in_dir(from_dir) | get_files_in_dir(to_dir)
      patch= files.sort
               .map{|f| diff_files f, from_dir ? "#{from_dir}/#{f}" : nil, "#{to_dir}/#{f}" }
               .compact
               .join("\n") + "\n"
      return nil if /\A\s*\z/ === patch

      if include_header
        from_digest= digest_dir(from_dir)
        to_digest= digest_dir(to_dir)
        patch_digest= DIGEST.hexdigest(patch)
        header= "Before: #{from_digest}\nAfter: #{to_digest}\nPatch: #{patch_digest}\n"

        header + patch
      else
        patch
      end
    end

    # Creates a new resource patch and writes changes to disk.
    #
    # Res-patches are designed so that the later patches are faster to reconstruct than older patches, thus in
    # performing this operation in addition to a new patch will being created, the current latest will also be updated
    # to be backwards reconstructable from the new latest.
    #
    # @param [String] from_dir The directory containing the contents of the last-packaged resources (i.e. matching the
    #   latest resource patch.)
    # @param [String] to_dir The directory containing the latest version of resources that will be the contents of the
    #   new resource patch.
    # @return [nil,Fixnum] The version of the new resource patch, else `nil` if there were no changes and one wasn't
    #   created.
    def create_res_patch_files!(from_dir, to_dir)
      raise "From-dir doesn't exist: #{from_dir}" unless Dir.exists?(from_dir)
      raise "To-dir doesn't exist: #{to_dir}" unless Dir.exists?(to_dir)
      raise "Resource patch dir doesn't exist: #{res_patch_dir}" unless Dir.exists?(res_patch_dir)

      content_backwards= create_res_patch_content to_dir, from_dir
      if content_backwards
        content_new= create_res_patch_content nil, to_dir

        prev_ver= latest_version
        prev_pkg= prev_ver == 0 ? nil : res_patch_filename(prev_ver)
        this_ver= prev_ver + 1
        this_pkg= res_patch_filename(this_ver)

        File.write prev_pkg, content_backwards if prev_pkg # TODO encoding
        File.write this_pkg, content_new # TODO encoding

        @latest_version= nil

        this_ver
      else
        nil
      end
    end

    # Deploys a specified version of resources to an empty directory.
    #
    # @param [String] target_dir The directory where the resources should be deployed to. If it doesn't exist, it will be
    #   created. If it exists, it must be empty.
    # @param [Fixnum,:latest] ver The version of resources to deploy.
    # @return [self]
    def deploy_resources(target_dir, ver)

      # Check version
      ver= latest_version if ver == :latest
      validate_version! ver, 0

      # Ensure we have an empty target directory
      Dir.mkdir target_dir unless Dir.exists?(target_dir)
      raise "Target directory must be empty." unless get_files_in_dir(target_dir).empty?

      # Deploy
      if ver > 0
        latest_version.downto(ver) do |v|
          apply_res_patch target_dir, v
        end
      end

      self
    end

    # Deploys the latest version of resources to an empty directory.
    #
    # @param [String] target_dir The directory where the resources should be deployed to. If it doesn't exist, it will be
    #   created. If it exists, it must be empty.
    # @return [self]
    def deploy_latest_resources(target_dir)
      deploy_resources target_dir, :latest
    end

    # Deploys a specified version of resources to a temporary directory and yields.
    #
    # Resources will be removed on method exit.
    #
    # @param [Fixnum,:latest] ver The version of resources to deploy.
    # @yieldparam [String] dir The directory containing the resources.
    # @return Whatever the yielded block returns.
    def with_resources(ver, &block)
      Dir.mktmpdir {|tmpdir|
        deploy_resources tmpdir, ver
        return block.call(tmpdir)
      }
    end

    # Deploys the latest version of resources to a temporary directory and yields.
    #
    # Resources will be removed on method exit.
    #
    # @yieldparam [String] dir The directory containing the resources.
    # @return Whatever the yielded block returns.
    def with_latest_resources(&block)
      with_resources :latest, &block
    end

    # Deploys a range of versions of resources to a temporary directory and yields.
    #
    # Resources will be removed on method exit.
    #
    # @param [Fixnum] from_ver The lowest version (inclusive) of resources to deploy. Must be >= 1.
    # @param [Fixnum,:latest] to_ver The highest version (inclusive) of resources to deploy. Must be >= `from_ver`.
    # @yieldparam [String] dir The directory containing subdirectories of each version of resources. Use {#ver_dir} to
    #   get the directory for a specific version.
    # @return Whatever the yielded block returns.
    # @see #ver_dir
    def with_resource_versions(from_ver, to_ver=:latest, &block)

      # Validate args
      raise "Block not provided." unless block
      to_ver= latest_version if to_ver == :latest
      validate_version! from_ver, 1, 'From-version'
      validate_version! to_ver, from_ver, 'To-version'

      # Explode patches into tmp dir
      with_reconstruction_dir do |base_dir|
        last_dir= nil
        last_dir_digest= digest_dir(base_dir) # it contains no files

        # Iterate over versions...
        to_ver.downto(from_ver) do |ver|
          this_dir= reconstruction_dir(ver)
          Dir.mkdir this_dir

          # Apply res patch for this version
          new_dir_digest= apply_res_patch this_dir, ver, last_dir_digest, last_dir

          # Prepare for next iteration
          last_dir= this_dir
          last_dir_digest= new_dir_digest
        end

        # Done. Yield control.
        return block.call base_dir

      end
    end

    # Provides a directory to the deployed resources of a given version. Use in conjunction with
    # {#with_resource_versions}.
    #
    # @param [Fixnum] ver The version of resources wanted.
    # @return [String] The directory of resources of the given version.
    # @raise If resources haven't been deployed yet.
    # @see #with_resource_versions
    def ver_dir(ver)
      raise "Reconstruction dir not yet defined." unless @reconstruction_dir
      "#{@reconstruction_dir}/#{ver}"
    end
    alias :reconstruction_dir :ver_dir

    # Allows the `patch` command to be run interactively and allow merge conflicts.
    #
    # @yield control with interactive patching enabled.
    # @return Whatever the yielded block returns.
    # @see #migrate
    def allow_interactive_patching
      before= @interactive_patching
      begin
        @interactive_patching= true
        yield
      ensure
        @interactive_patching= before
      end
    end

    # Returns whether interactive patching is enabled.
    #
    # @return [Boolean]
    # @see #allow_interactive_patching
    def interactive_patching?
      @interactive_patching
    end

    # Patches up files initially deployed at ver A, to ver B.
    #
    # You will likely want to run this in conjunction with {#allow_interactive_patching}.
    #
    # @param [nil,Fixnum] from_ver The version previously deployed. If nothing has been deployed previously, use `nil`
    #   or 0.
    # @param [Fixnum] to_ver The target version.
    # @param [String] target_dir The directory containing the resources to patch.
    # @param [nil,Array<String>] filelist The list of files to patch. If `nil` then all files will patched.
    # @return [Boolean] Whether there were any merge conflicts.
    # @raise If resources haven't been deployed yet.
    # @see #allow_interactive_patching
    # @see #with_resource_versions
    def migrate(from_ver, to_ver, target_dir, filelist=nil)
      from_ver ||= 0
      raise "Invalid from-version. Must be a number >= 0." unless from_ver.is_a?(Fixnum) and from_ver >= 0
      raise "Invalid to-version. Must be a number." unless to_ver.is_a?(Fixnum)
      raise "Invalid versions. Can't migrate backwards." unless to_ver >= from_ver

      merge_conflicts= false

      # Check if anything to do: version
      unless from_ver == to_ver

        # Build list of files
        if filelist.nil?
          filelist= []
          for v in from_ver..to_ver do
            next if v == 0
            src_dir= reconstruction_dir(v)
            raise "Reconstruction dir for v#{v} not found: #{src_dir}" unless Dir.exists?(src_dir)
            filelist.concat get_files_in_dir(src_dir)
          end
        end
        filelist= filelist.inject({}){|h,f| h[f] ||= {}; h }

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
            patch= diff_files f, from_file, to_file
            patches[f]= patch if patch
          end
        end

        # Apply patches
        unless patches.empty?
          megapatch= patches.keys.sort.map{|f| patches[f]}.join($/) + $/
          #puts '_'*80; puts megapatch; puts '_'*80
          merge_conflicts= apply_patch target_dir, megapatch
        end
      end

      merge_conflicts
    end

    # Returns the filename of a resource patch for a given version.
    #
    # @param [Fixnum] ver The resource patch version.
    # @return [String] The resource patch filename.
    def res_patch_filename(ver)
      '%s/%05d.patch' % [res_patch_dir,ver]
    end

    private
    DIGEST= Digest::SHA2

    # Gets a list of files in a directory tree.
    #
    # @param [nil,String] dir The directory to inspect.
    # @return [Array<String>] A list of files relative to `dir`, or an empty array if `dir` is `nil`.
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

    # Diffs two files.
    #
    # @param [String] relative_filename The filename to store in the patch that is relative to our resource directory.
    # @param [nil,String] from_file The full path to file A. Use `nil` if new file.
    # @param [nil,String] to_file The full path to file B. Use `nil` if file deleted.
    def diff_files(relative_filename, from_file, to_file)
      from_file= '/dev/null' unless from_file and File.exists? from_file
      to_file= '/dev/null' unless to_file and File.exists? to_file
      patch= `#{diff_exe} -u #{from_file.inspect} #{to_file.inspect}`
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
        raise "Diff failed with exit status #{$?.exitstatus} trying to compare #{relative_filename}"
      end
    end

    # Invokes the `patch` command.
    #
    # @param [String] patch The patch contents.
    # @return [Boolean] Whether there was a merge conflict or not. Can only be `true` during
    #   {#allow_interactive_patching}.
    # @see #interactive_patching?
    def apply_patch(target_dir, patch)
      Dir.chdir target_dir do
        tmp= Tempfile.new('corvid-migration')
        begin
          tmp.write patch
          tmp.close

          merge_conflict= false

          # patch's  exit  status  is  0 if all hunks are applied successfully, 1 if some
          # hunks cannot be applied or there were merge conflicts, and 2 if there is more
          # serious trouble.  When applying a set of patches in a loop it behooves you to
          # check this exit status so you don't  apply  a  later  patch  to  a  partially
          # patched file.

          cmd= "#{patch_exe} -p0 --unified -i #{tmp.path.inspect}"
          if interactive_patching?
            system "#{cmd} --backup-if-mismatch --merge"
            case $?.exitstatus
            when 0
              # Great!
            when 1
              merge_conflict= true
            else
              raise "Problem occured applying patches. Exit status = #{$?.exitstatus}."
            end
          else
            `#{cmd} --batch`
            raise "Failed to apply patch. Exit status = #{$?.exitstatus}." unless $?.success?
          end

          return merge_conflict
        ensure
          tmp.close
          tmp.delete
        end
      end
    end

    # Generates a checksum representing the contents of all files in a directory tree.
    # @param [nil,String] dir
    # @return String A single checksum.
    def digest_dir(dir)
      digests= get_files_in_dir(dir){|f| DIGEST.file f}
      DIGEST.hexdigest digests.join(nil)
    end

    def read_digest_from_res_patch_header(header_lines, title)
      v= header_lines.map{|l| l =~ /^#{title}:\s+([0-9a-f]+)\s*$/; $1 ? $1.dup : nil }.compact.first
      v || raise("Checksum '#{title}' not found in patch header.")
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

    # Deploys resources by applying a res-patch (i.e. a single version).
    #
    # @param [String] target_dir The directory where the resources will be deployed to. Must exist.
    # @param [Fixnum] ver The version of resources to deploy.
    # @param [nil,String] digest_before The hex digest of the contents of the previous directory. This will be compared
    #   to the *before* checksum in the resource patch before applying. If `nil` then a digest will be calculated for
    #   the target directory before applying the patch.
    # @param [nil,String] prev_ver_dir The directory containing the already-deployed contents of this target version + 1.
    #   If provided then the contents of the directory will be copied to `target_dir` before applying the patch.
    # @return [String] The digest of the target dir on completion.
    # @raise If any digest checking tests fail.
    def apply_res_patch(target_dir, ver, digest_before=nil, prev_ver_dir=nil)

      # Read migration patch
      patch_data= read_res_patch(ver)

      # Copy previous version into target directory
      FileUtils.cp_r "#{prev_ver_dir}/.", target_dir if prev_ver_dir

      # Check before-checksum
      digest_before ||= digest_dir(target_dir)
      if patch_data[:digest_before] != digest_before
        errmsg= "Cannot apply res-patch ##{ver} to #{target_dir}. Its contents do not match those that the patch expects to be applied to."
        errmsg+= " Ensure that the 'after' checksum of res-patch ##{ver+1} matches the 'before' checksum of #{ver}." unless ver == latest_version
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

    # Creates a temporary directory or uses a given one as the base reconstruction dir.
    def with_reconstruction_dir(dir=nil, &block)
      if dir.nil?
        Dir.mktmpdir {|d| with_reconstruction_dir d, &block }
      else
        raise "Reconstruction dir already set. Nesting not supported." if @reconstruction_dir
        raise "Invalid reconstruction dir; it doesn't exist: #{dir}" unless Dir.exists?(dir)
        begin
          @reconstruction_dir= dir
          block.call dir
        ensure
          @reconstruction_dir= nil
        end
      end
    end

    def correct_filename_in_patchline!(line, filename)
      return line if %r!^(?:-{3}|\+{3})\s+?/dev/null\t! === line
      line.sub! /(?<=^(?:-{3}|\+{3})\s).+?(?=\t)/, filename
    end

  end
end
