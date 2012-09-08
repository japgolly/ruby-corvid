desc 'Displays TODOs in source code and other project files.'
task :todo do
  # TODO Create a .corvid/todo-ignore.lst or something
  cmd= <<-EOB

    find . -type f ! "(" \
      -path '*/.git*'                 -o\
      -path '*/target/*'              -o\
      -path '*/resources/latest/*.tt' -o\
      -path '*/test/fixtures/*.gemspec' -o\
      -name '.*.sw[p-z]'              -o\
      -name '*.patch'                 -o\
      -path '*/tasks/todo.rb'           \
    ")" | sort | xargs egrep --color=always -n 'TODO.*$'

  EOB
  x= `#{cmd}`
  puts "Found #{x.split($/).size} TODOs."
  puts x
end
