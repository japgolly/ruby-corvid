namespace :dev do

  desc 'Syncs test fixture deps with main.'
  task :fixture_gems do
    ENV['BUNDLE_GEMFILE']= nil
    ENV['RUBYOPT']= nil
    CORVID_ROOT ||= File.expand_path('../..',__FILE__)

    require "#{CORVID_ROOT}/test/helpers/gemfile_patching"

    GemfilePatching.prepare_corvid_deps_patch {
      dirs= `find test/fixtures -name Gemfile.lock`.split($/).reject(&:empty?).sort.reverse # reverse do deepest happens first
      dirs.map{|f| File.dirname f}.each {|dir|
        puts "#{dir} ..."
        begin
          GemfilePatching.apply_corvid_deps_patch dir, true
          puts "Success."
        rescue
        end
        puts
      }
    }
    system "git st -- test/fixtures"
  end

end
