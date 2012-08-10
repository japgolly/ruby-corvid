# encoding: utf-8

STDIN.close

require_relative '../lib/corvid/environment'
$:<< "#{CORVID_ROOT}/test" # Add test/ to lib path

require 'corvid/builtin/manifest'
require 'corvid/test/helpers/plugins'
require 'helpers/gemfile_patching'
require 'golly-utils/testing/rspec/files'
require 'golly-utils/testing/rspec/arrays'
require 'fileutils'
require 'tmpdir'
require 'yaml'

RUN_BUNDLE= 'run_bundle'
BOOTSTRAP_ALL= 'test/bootstrap/all.rb'
BOOTSTRAP_UNIT= 'test/bootstrap/unit.rb'
BOOTSTRAP_SPEC= 'test/bootstrap/spec.rb'
BUILTIN_PLUGIN= Corvid::Builtin::Manifest
BUILTIN_FEATURES= BUILTIN_PLUGIN.new.feature_manifest.keys.map(&:freeze).freeze
CORVID_BIN= "#{CORVID_ROOT}/bin/corvid"
CORVID_BIN_Q= CORVID_BIN.inspect

module Fixtures
  FIXTURE_ROOT= "#{CORVID_ROOT}/test/fixtures"
end

module TestHelpers

  def add_feature!(feature_name)
    f= YAML.load_file('.corvid/features.yml') + [feature_name]
    File.write '.corvid/features.yml', f.to_yaml
  end

  def assert_corvid_features(*expected)
    f= YAML.load_file('.corvid/features.yml')
    f.should be_kind_of(Array)
    f.should == expected.flatten
  end

  def invoke_sh(cmd,env=nil)
    cmd= cmd.map(&:inspect).join ' ' if cmd.kind_of?(Array)
    env ||= {}
    env['BUNDLE_GEMFILE'] ||= nil
    env['RUBYOPT'] ||= nil
    system env, cmd
    $?.success?
  end
  def invoke_sh!(args,env=nil)
    invoke_sh(args,env).should eq(true), 'Shell command failed.'
  end
  def invoke_corvid(args,env=nil)
    args= args.map(&:inspect).join ' ' if args.kind_of?(Array)
    args= args.gsub /^\s+|\s+$/, ''
    cmd= "#{CORVID_BIN_Q} #{args}"
    cmd.gsub! /\n| && /, " && #{CORVID_BIN_Q} "
    invoke_sh cmd, env
  end
  def invoke_corvid!(args,env=nil)
    invoke_corvid(args,env).should eq(true), 'Corvid failed.'
  end
  def invoke_rake(args,env=nil)
    args= args.map(&:inspect).join ' ' if args.kind_of?(Array)
    cmd= "bundle exec rake #{args}"
    invoke_sh cmd, env
  end
  def invoke_rake!(args,env=nil)
    invoke_rake(args,env).should eq(true), 'Rake failed.'
  end

  # TODO remove files() and dirs() test helpers.
  def files(force=false)
    @files= nil if force
    @files ||= Dir['**/*'].select{|f| ! File.directory? f}.sort
  end
  def dirs(force=false)
    @dirs= nil if force
    @dirs ||= Dir['**/*'].select{|f| File.directory? f}.sort
  end

  def copy_fixture(fixture_name, target_dir='.')
    FileUtils.cp_r "#{Fixtures::FIXTURE_ROOT}/#{fixture_name}/.", target_dir
  end

  def inside_fixture(fixture_name)
    Dir.mktmpdir {|dir|dir
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

  def run_generator(generator_class, args, no_bundle=true, quiet=true)
    args= args.split(/\s+/) unless args.is_a?(Array)
    args<< "--no-#{RUN_BUNDLE}" if no_bundle

    config= generator_config(quiet)

    # Do horrible stupid Thor-internal crap to instantiate a generator
    task= generator_class.tasks[args.shift]
    args, opts = Thor::Options.split(args)
    config.merge!(:current_task => task, :task_options => task.options)
    g= generator_class.new(args, opts, config)

    decorate_generator g
    g.invoke_task task
  end
end

module IntegrationTestDecoration
  SEP1= "\e[0;40;34m#{'_'*120}\e[0m"
  SEP2= "\e[0;40;34m#{'-'*120}\e[0m"
  SEP3= "\e[0;40;34m#{'='*120}\e[0m"
  def self.included spec
    spec.class_eval <<-EOB
      before(:all) { puts ::#{self}::SEP1 }
      before(:each){ puts ::#{self}::SEP2 }
      after(:all)  { puts ::#{self}::SEP3 }
    EOB
  end
end

RSpec.configure do |config|
  config.include Corvid::PluginTestHelpers
  config.include GemfilePatching
  config.include TestHelpers
end
