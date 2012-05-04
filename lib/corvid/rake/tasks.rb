unless defined?(APP_ROOT)
  $stderr.puts "ERROR: APP_ROOT is not defined.\nIt should be defined in your Rakefile before loading Corvid."
  exit 1
end

Bundler.require :rake

Dir["#{File.dirname __FILE__}/tasks/**/*.{rb,rake}"].each{|f| require f }
