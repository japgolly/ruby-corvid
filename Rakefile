require 'bundler/gem_tasks'
CORVID_ROOT= File.expand_path '..', __FILE__
$:<< "#{CORVID_ROOT}/lib"

def relative_to_corvid_root(dir)
  dir.sub /^#{Regexp.quote CORVID_ROOT}[\\\/]+/, ''
end

desc "Test specifications."
task :test do
  require 'rspec/core/rake_task'
  RSpec::Core::RakeTask.new(:test) do |t|
    t.rspec_path= "bin/rspec"
    t.pattern= "test/spec{,/*,/**}/*_spec.rb"
  end
end

Dir["#{CORVID_ROOT}/tasks/**/*.{rb,rake}"].each{|f| import f }

