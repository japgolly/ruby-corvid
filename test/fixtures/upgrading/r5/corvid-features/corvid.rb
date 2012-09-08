requirements 'corvid:whatever'

install {
  empty_directory 'lib.1'
  empty_directory 'lib.2'
  empty_directory 'lib.3'
  copy_file 'corvid.A'
  copy_executable 'corvid.C'
}

update {|ver|
  case ver
  when 2
    empty_directory 'lib.2'
    copy_file 'corvid.B'
  when 3
    empty_directory 'lib.3'
    copy_executable 'corvid.C'
  end
}
