require 'golly-utils/testing/dynamic_fixtures'

RSpec.configure do |config|
  config.include GollyUtils::Testing::DynamicFixtures
end

module GollyUtils::Testing::DynamicFixtures

  def_fixture :bare_no_gemfile_lock, dir_name: 'int_test' do
    invoke_corvid! "init --no-#{RUN_BUNDLE} --no-test-unit --no-test-spec"
    init_gemfile true, false
  end

  def_fixture :new_cool_plugin do
    invoke_corvid! %(
      init --no-#{RUN_BUNDLE} --no-test-unit --no-test-spec
      init:plugin --no-#{RUN_BUNDLE}
      new:plugin cool
    )
    init_gemfile
    gsub_file! /(add_dependency_to_gemfile.+)$/, "\\1, path: File.expand_path('../../..',__FILE__)",
      'lib/new_cool_plugin/cool_plugin.rb'
  end

  def_fixture :new_hot_feature do
    copy_dynamic_fixture :new_cool_plugin
    invoke_corvid! 'new:feature hot'
  end

  def_fixture :plugin do
    copy_fixture 'plugin'
    %w[client_project plugin_project].each do |dir|
      Dir.chdir dir do
        # Remove expanded resources
        FileUtils.rm_rf 'resources/latest'

        # Change relative paths to Corvid, into absolute paths
        gsub_files! %r|(?<![./a-z])\.\./\.\./\.\./\.\.(?![./a-z])|, "#{CORVID_ROOT}", 'Gemfile', '.corvid/Gemfile'

        # Regenerate bundle lock files
        gsub_file! /^GEM.+\z/m, '', 'Gemfile.lock'
        invoke_sh! 'bundle install --local --quiet'
      end
    end
  end

  def_fixture :client_with_plugin, cd_into: 'client_project' do
    copy_dynamic_fixture :plugin
  end

  def_fixture :client_with_plugin_and_feature, cd_into: 'client_project' do
    copy_dynamic_fixture :plugin
    FileUtils.cp_r "p1f1_installation_changes/.", "client_project"
  end

end
