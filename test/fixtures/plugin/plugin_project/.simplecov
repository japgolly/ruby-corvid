SimpleCov.start do
  # project_name 'My Awesome Project'

  # add_group 'Models', 'app/model'
  # add_group 'Plugins', '(app|lib)/plugins'

  # Exclude tests from coverage
  add_filter '^(?:(?<!/(?:app|lib)/).)*/test/'

  # Add files that don't get required to coverage too
  add_files_to_coverage_at_exit '{app,lib}/**/*.rb'

  # Skip LOC that contain nothing but "end", "ensure", and so on.
  skip_boring_loc_in_coverage
end

# vim:ft=ruby et ts=2 sw=2:
