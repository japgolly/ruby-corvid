# Hacks, some quite horrible, that patch gemfiles and the like so that integration tests use the WIP version of
# corvid, along with its WIP dependencies.
module GemfilePatching
  extend self

  def gsub_files!(pattern, replacement, *files)
    files.flatten.uniq.each do |file|
      if File.exists? file
        c= File.read file
        c.gsub! pattern, replacement
        File.write file, c
      end
    end
  end
  alias :gsub_file! :gsub_files!

  # Files:
  # * `Gemfile`
  # * `.corvid/Gemfile`.
  #
  # Changes:
  # * Corvid library to be sourced directly by specifying `path: '...'`
  def patch_corvid_gemfile
    gsub_files! /^\s*(gem\s+.corvid.)\s*(?:,\s*path.*)?$/, %|\\1, path: "#{CORVID_ROOT}"|, %w[Gemfile .corvid/Gemfile]
    true
  end

  # Files:
  # * `Gemfile`
  #
  # Changes:
  # * Deps sourced directly from git in Corvid's `Gemfile`, will also be sourced from Git in target `Gemfile`
  def patch_corvid_deps(dir='.')
    prepare_corvid_deps_patch{ apply_corvid_deps_patch dir }
  end

  def prepare_corvid_deps_patch
      system %Q[sed -n 's/^ *\|#.*//g; /^gem .*git:/w /tmp/gem.tmp' "#{CORVID_ROOT}"/Gemfile]
      system %q[sed -i '/yard/d' /tmp/gem.tmp] # Exclude yard. Hackity hack hack!
      yield
      system "rm -f /tmp/gem.tmp"
  end

  def apply_corvid_deps_patch(dir='.', local=false)
    local= local ? '--local' : ''
#    sed -n 's/[ \t'"'"'"]//g; s/gem\([^,]*\),.*$/\1/p' /tmp/gem.tmp
    system <<-EOB
      cd "#{dir}" \
      && rm -f Gemfile.lock \
      && sed -i -n '/^ *gem .*git:/!p; $r /tmp/gem.tmp' Gemfile \
      && cp "#{CORVID_ROOT}"/Gemfile.lock . \
      && BUNDLE_GEMFILE= bundle install #{local} --quiet
    EOB
    raise "Something went wrong: exit status = #{$?.exitstatus}" unless $?.success?
  end

end
