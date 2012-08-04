namespace :dev do

  desc 'Syncs test fixture deps with main.'
  task :fixture_gems do
    ENV['BUNDLE_GEMFILE']= nil
    ENV['RUBYOPT']= nil
    CORVID_ROOT ||= File.expand_path('../..',__FILE__)

    # Gemfile.lock
    system %q[sed -n 's/^ *\|#.*//g; /^gem .*git:/w gem.tmp' Gemfile]
    dirs= `find test/fixtures -name Gemfile.lock`.split($/).reject(&:empty?).sort.reverse # reverse do deepest happens first
    dirs.map{|f| File.dirname f}.each {|dir|
      Dir.chdir(dir) {
        #puts "#{'-'*80}\n#{dir}\n\n"
        puts "#{dir} ..."
        system <<-EOB
          rm -f Gemfile.lock \
          && sed -i -n '/^ *gem .*git:/!p; $r #{CORVID_ROOT}/gem.tmp' Gemfile \
          && BUNDLE_GEMFILE= bundle install --local --quiet
        EOB
        puts $?.success? ? "Success." : "Failed: #{$?.exitstatus}"
        puts
      }
    }
    system "rm gem.tmp; git st -- test/fixtures"
  end

end
