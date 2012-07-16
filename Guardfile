rspec_cli= File.read(File.expand_path('../.rspec',__FILE__))
  .gsub(/\s+/,' ')
  .gsub('--order random','--order default')

########################################################################################################################
# test/spec

group :spec do
  guard 'rspec', binstubs: true, spec_paths: ['test/spec'], cli: rspec_cli, all_on_start: false, all_after_pass: false do

    # Each spec
    watch(%r'^test/spec/.+_spec\.rb$')

    # Lib
    watch(%r'^lib/corvid/(.+)\.rb$') {|m| "test/spec/#{m[1]}_spec.rb"}

    # Plugin tests
    watch(%r'^.*plugin.*$') {|m| "test/spec/plugins_spec.rb"}
  end
end
