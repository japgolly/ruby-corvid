desc "Displays T\ODOs in source code and other project files."
task :todo do

  # Create finder
  require 'corvid/builtin/todo_finder'
  todo_finder= Corvid::TodoFinder.new

  # Allow external customisation
  file= "#{APP_ROOT}/.corvid/todo_cfg.rb"
  if File.exists? file
    o= Object.new
    o.instance_eval "def todo_finder; @todo_finder end"
    o.instance_variable_set :@todo_finder, todo_finder
    o.instance_eval File.read(file)
  end

  # Run and display results
  r= `#{todo_finder.cmd}`
  puts "Found #{r.split($/).size} T\ODOs."
  puts r
end

