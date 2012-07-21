require 'corvid/guard'

########################################################################################################################
# test/unit

group :unit do
  guard 'minitest', test_folders: 'test/unit', test_file_patterns: '*_test.rb' do

    # Src files
    watch(%r'^lib/(.+)\.rb$') {|m| "test/unit/#{m[1]}_test.rb"}

    # Each test
    watch(%r'^test/unit/.+_test\.rb$')

    if bulk?
      # Test stuff affecting everything
      watch(%r'^test/bootstrap/(?:all|unit).rb') {"test/unit"}
      watch(%r'^test/helpers/.+$')               {"test/unit"}
      watch(%r'^test/factories/.+$')             {"test/unit"}
    end
  end
end if Dir.exists?('test/unit')

########################################################################################################################
# test/spec

rspec_options= read_rspec_options(File.dirname __FILE__)
group :spec do
  guard 'rspec', binstubs: true, spec_paths: ['test/spec'], cli: rspec_options, all_on_start: false, all_after_pass: false do

    # Src files
    watch(%r'^lib/(.+)\.rb$') {|m| "test/spec/#{m[1]}_spec.rb"}

    # Each spec
    watch(%r'^test/spec/.+_spec\.rb$')

    if bulk?
      # Test stuff affecting everything
      watch(%r'^test/bootstrap/(?:all|spec).rb') {"test/spec"}
      watch(%r'^test/helpers/.+$')               {"test/spec"}
      watch(%r'^test/factories/.+$')             {"test/spec"}
    end
  end
end if Dir.exists?('test/spec')
