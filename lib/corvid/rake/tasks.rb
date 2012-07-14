unless defined?(APP_ROOT)
  $stderr.puts "ERROR: APP_ROOT is not defined.\nIt should be defined in your Rakefile before loading Corvid."
  exit 1
end

Bundler.require :rake

# Helper methods
def prompt(msg)
  STDERR.print "#{msg} [yn]: "
  while true
    case STDIN.gets.chomp!
    when /^\s*(y(es)?)?\s*$/i then return true
    when /^\s*no?\s*$/i then return false
    else
      STDERR.print "Sorry, I don't understand. Please type y or n: "
    end
  end
end

# Load corvid rake-tasks
Dir["#{File.dirname __FILE__}/tasks/**/*.rb"].each{|f| require f }

# Load application rake-tasks
Dir["#{APP_ROOT}/tasks/**/*.{rb,rake}"].each{|f| import f }
