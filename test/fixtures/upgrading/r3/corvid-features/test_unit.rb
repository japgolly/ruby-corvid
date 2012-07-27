def install
  empty_directory 'test.1'
  empty_directory 'test.2'
  empty_directory 'test.3'
  copy_file 'test.A'
  copy_file 'test.B'
  copy_executable 'test.C'
end
