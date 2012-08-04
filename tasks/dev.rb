namespace :dev do

  desc 'Syncs test fixture deps with main.'
  task :fixture_gems do
    ENV['BUNDLE_GEMFILE']= nil
    ENV['RUBYOPT']= nil

    # Gemfile.lock
    system %q[sed -n 's/^ *\|#.*//g; /yard/d; /^gem .*git:/w gem.tmp' Gemfile]
    dirs= `find test/fixtures -name Gemfile.lock`.split($/).reject(&:empty?).sort.reverse # reverse do deepest happens first
    dirs.map{|f| File.dirname f}.each {|dir|
      Dir.chdir(dir) {
        #puts "#{'-'*80}\n#{dir}\n\n"
        puts "#{dir} ..."
        system <<-EOB
          t="#{CORVID_ROOT}/gem.tmp" \
          && rm -f Gemfile.lock \
          && sed -i '/^ *gem .*git:/d; $r '"$t" Gemfile \
          && BUNDLE_GEMFILE= bundle install --local --quiet
        EOB
        puts $?.success? ? "Success." : "Failed: #{$?.exitstatus}"
        puts
      }
    }
    system "rm gem.tmp; git st -- test/fixtures"
  end

end
