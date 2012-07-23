unless defined?(APP_ROOT)
  $stderr.puts "ERROR: APP_ROOT is not defined.\nIt should be defined in your Rakefile before loading Corvid."
  exit 1
end

Bundler.require :rake

# Load corvid rake-tasks
Dir["#{File.dirname __FILE__}/tasks/**/*.rb"].each{|f| require f }

# Load application rake-tasks
Dir["#{APP_ROOT}/tasks/**/*.{rb,rake}"].each{|f| import f }
