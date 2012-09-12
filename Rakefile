APP_ROOT= CORVID_ROOT= File.expand_path(File.dirname(__FILE__))
$:<< "#{CORVID_ROOT}/lib"

# Load external tasks
namespace(:gem){ require 'bundler/gem_tasks' } # TODO should this be in all?
require 'corvid/builtin/rake/tasks/clean'
require 'corvid/builtin/rake/tasks/doc'
require 'corvid/builtin/rake/tasks/resources'
require 'corvid/builtin/rake/tasks/stats'
require 'corvid/builtin/rake/tasks/todo'

# Load local tasks
Dir["#{CORVID_ROOT}/tasks/**/*.{rb,rake}"].each{|f| import f }
