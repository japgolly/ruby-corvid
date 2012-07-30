def install
  empty_directory 'lib.1'
  empty_directory 'lib.2'
  copy_file 'corvid.A'
  copy_file 'corvid.B'
end

def update(ver)
  case ver
  when 2
    empty_directory 'lib.2'
    copy_file 'corvid.B'
  end
end
