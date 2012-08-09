install {
  copy_file       'Rakefile'
  empty_directory 'lib'
  #empty_directory 'wtffff'
}

update {|ver|
  if ver == 2
    empty_directory 'wtffff'
  end
}
