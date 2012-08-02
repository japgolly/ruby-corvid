rspec_cli= File.read(File.expand_path('../.rspec',__FILE__))
  .gsub(/\s+/,' ')
  .gsub('--order random','--order default')

########################################################################################################################
# test/spec

group :spec do
  guard 'rspec', binstubs: true, spec_paths: ['test/spec'], cli: rspec_cli, all_on_start: false, all_after_pass: false, keep_failed: false do
    #watch(%r{^(.+)$}) { |m| puts "------------------------------------------> #{m[1]} modified" }

    # Ignore Vim swap files
    ignore /~$/
    ignore /^(?:.*[\\\/])?\.[^\\\/]+\.sw[p-z]$/

    # Each spec
    watch(%r'^test/spec/.+_spec\.rb$')

    # Lib
    watch(%r'^lib/corvid/(.+)\.rb$') {|m| "test/spec/#{m[1]}_spec.rb"}

    # Plugin tests
    watch(%r'^.*plugin.*$') {|m| "test/spec/plugins_spec.rb"}

    # Fixtures
    watch(%r'^test/fixtures/migration/.+$')  {"test/spec/res_patch_manager_spec.rb"}
    upgrading= %w[test/spec/generators/init_spec.rb test/spec/generators/update_spec.rb]
    watch(%r'^test/fixtures/upgrading/.+$')   {upgrading}
    watch('test/helpers/fixture-upgrading.rb'){upgrading}
  end
end
