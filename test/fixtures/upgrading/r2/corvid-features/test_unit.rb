def install
  empty_directory 'test.1'
  empty_directory 'test.2'
  copy_file 'test.A'
  copy_file 'test.B'
end
