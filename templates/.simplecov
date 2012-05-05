SimpleCov.start do
  # project_name 'My Awesome Project'

  # add_group 'Models', 'app/model'
  # add_group 'Plugins', '(app|lib)/plugins'

  # Remove test code from coverage
  add_filter 'test'

  # Add files that don't get required to coverage too
  add_files_to_coverage_at_exit '{app,lib}/**/*.rb'
end

# vim:ft=ruby et ts=2 sw=2:
