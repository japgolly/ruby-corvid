desc "Displays T\ODOs in source code and other project files."
task :todo do

  # Create finder
  require 'corvid/builtin/todo_finder'
  t= Corvid::TodoFinder.new

  # TODO Allow external customisation

  # Run and display results
  r= `#{t.cmd}`
  puts "Found #{r.split($/).size} T\ODOs."
  puts r
end

