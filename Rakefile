APP_ROOT= CORVID_ROOT= File.expand_path(File.dirname(__FILE__))
$:<< "#{CORVID_ROOT}/lib"

# Load external tasks
namespace(:gem){ require 'bundler/gem_tasks' }
require 'corvid/rake/tasks/clean'
require 'corvid/rake/tasks/doc'
require 'corvid/rake/tasks/resources'

# Load local tasks
Dir["#{CORVID_ROOT}/tasks/**/*.{rb,rake}"].each{|f| import f }

