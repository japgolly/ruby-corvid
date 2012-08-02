APP_ROOT= CORVID_ROOT= File.expand_path(File.dirname(__FILE__))
$:<< "#{CORVID_ROOT}/lib"

# Load external tasks
require 'bundler/gem_tasks'
require 'corvid/rake/tasks/clean'
require 'corvid/rake/tasks/doc'

# Load local tasks
def relative_to_corvid_root(dir)
  dir.sub /^#{Regexp.quote CORVID_ROOT}[\\\/]+/, ''
end
Dir["#{CORVID_ROOT}/tasks/**/*.{rb,rake}"].each{|f| import f }

