# encoding: utf-8

STDIN.close

require_relative '../../lib/corvid/environment'
$:<< "#{CORVID_ROOT}/test" # Add test/ to lib path

require 'corvid/constants'
require 'corvid/builtin/builtin_plugin'
require 'corvid/test/helpers/plugins'
require 'helpers/gemfile_patching'
require 'helpers/dynamic_fixtures'
require 'golly-utils/testing/rspec/files'
require 'golly-utils/testing/rspec/arrays'
require 'fileutils'
require 'tmpdir'
require 'yaml'

RUN_BUNDLE= 'run_bundle'
BOOTSTRAP_ALL= 'test/bootstrap/all.rb'
BOOTSTRAP_UNIT= 'test/bootstrap/unit.rb'
BOOTSTRAP_SPEC= 'test/bootstrap/spec.rb'
BUILTIN_PLUGIN= Corvid::Builtin::BuiltinPlugin
BUILTIN_FEATURES= BUILTIN_PLUGIN.new.feature_manifest.keys.map(&:freeze).freeze
CORVID_BIN= "#{CORVID_ROOT}/bin/corvid"
CORVID_BIN_Q= CORVID_BIN.inspect
CONST= Corvid::Constants
BUILTIN_PLUGIN_DETAILS= {'corvid'=>{path: 'corvid/builtin/builtin_plugin', class: 'Corvid::Builtin::BuiltinPlugin'}}

module Fixtures
  FIXTURE_ROOT= "#{CORVID_ROOT}/test/fixtures"
end

module TestHelpers

  def copy_fixture(fixture_name, target_dir='.')
    FileUtils.cp_r "#{Fixtures::FIXTURE_ROOT}/#{fixture_name}/.", target_dir
  end

  def inside_fixture(fixture_name)
    Dir.mktmpdir {|dir|
      Dir.chdir dir do
        copy_fixture fixture_name
        patch_corvid_gemfile
        yield
      end
    }
  end

  def assert_files(src_dir, exceptions={})
    filelist= Dir.chdir(src_dir){
      Dir.glob('**/*',File::FNM_DOTMATCH).select{|f| File.file? f }
    } + exceptions.keys
    filelist.uniq!
    get_files.should == filelist.sort
    filelist.each do |f|
      expected= exceptions[f] || File.read("#{src_dir}/#{f}")
      File.read(f).should == expected
    end
  end

  def create_gemspec_file(project_name)
    content= File.read("#{CORVID_ROOT}/corvid.gemspec")
                 .gsub('corvid',project_name)
    File.write "#{project_name}.gemspec", content
  end

  def self.included base
    base.extend ClassMethods
  end
  module ClassMethods

    def run_each_in_fixture(fixture_name)
      class_eval <<-EOB
        around :each do |ex|
          inside_fixture(#{fixture_name.inspect}){ ex.run }
        end
      EOB
    end

  end
end

module DynamicFixtures
  def_fixture :bare do
    require 'corvid/res_patch_manager'
    Dir.mkdir '.corvid'
    add_plugin! BUILTIN_PLUGIN.new
    add_feature! 'corvid:corvid'
    add_version! 'corvid', Corvid::ResPatchManager.new.latest_version
  end

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

RSpec.configure do |config|
  config.include Corvid::PluginTestHelpers
  config.include GemfilePatching
  config.include TestHelpers
  config.include DynamicFixtures
  config.after(:each){
    Corvid::PluginRegistry.clear_cache if defined? Corvid::PluginRegistry
    Corvid::FeatureRegistry.clear_cache if defined? Corvid::FeatureRegistry
    Corvid::Generator::TemplateVars.reset_template_var_cache if defined? Corvid::Generator::TemplateVars
  }
  config.treat_symbols_as_metadata_keys_with_true_values= true
end
