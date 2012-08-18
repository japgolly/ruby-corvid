# encoding: utf-8

STDIN.close

require_relative '../lib/corvid/environment'
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

  def invoke_sh(cmd,env=nil)
    cmd= cmd.map(&:inspect).join ' ' if cmd.kind_of?(Array)
    env ||= {}
    env['BUNDLE_GEMFILE'] ||= nil
    env['RUBYOPT'] ||= nil
    unless @capture_sh
      cmd+= ' >/dev/null' if [true,1].include? @quiet_sh
      cmd+= ' 2>/dev/null' if [true,2].include? @quiet_sh
    end

    @_sh_env,@_sh_cmd = env,cmd
    if @capture_sh
      require 'open3'
      Open3.popen3 env, cmd do |stdin, stdout, stderr, wait_thr|
        stdin.close
        @_sh_process= wait_thr.value
        @stdout= stdout.read
        @stderr= stderr.read
      end
    else
      system env, cmd
      @_sh_process= $?
    end

    @_sh_process.success?
  end

  def invoke_corvid(args='',env=nil)
    args= args.map(&:inspect).join ' ' if args.kind_of?(Array)
    args= args.gsub /^\s+|\s+$/, ''
    cmd= "#{CORVID_BIN_Q} #{args}"
    cmd.gsub! /\n| && /, " && #{CORVID_BIN_Q} "
    invoke_sh cmd, env
  end

  def invoke_rake(args='',env=nil)
    args= args.map(&:inspect).join ' ' if args.kind_of?(Array)
    cmd= "bundle exec rake #{args}"
    invoke_sh cmd, env
  end

  def invoke_sh!    (args,   env=nil) validate_sh_success{ invoke_sh     args,env } end
  def invoke_corvid!(args='',env=nil) validate_sh_success{ invoke_corvid args,env } end
  def invoke_rake!  (args='',env=nil) validate_sh_success{ invoke_rake   args,env } end
  def validate_sh_success
    yield.should be_true
  rescue => e
    puts '>'*60
    puts "ENV: #{@_sh_env}"
    puts "CMD: #{@_sh_cmd}"
    p @_sh_process
    puts
    puts @stdout if @stdout
    puts @stderr if @stderr
    puts '<'*60
    raise e
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

  def mock_new(klass, real=false)
    instance= case real
              when false then mock "Mock #{klass}"
              when true  then klass.new
              else real
              end
    klass.should_receive(:new).and_return(instance)
    instance
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

    def add_generator_lets
      class_eval <<-EOB
        let(:fr){ Corvid::FeatureRegistry.send :new }
        let(:pr){ Corvid::PluginRegistry.send :new }
        let(:subject){
          g= quiet_generator(described_class)
          g.plugin_registry= pr
          g.feature_registry= fr
          g.stub(:rpm_for).and_raise('rpm_for() called with wrong args')
          g.stub :say
          g
        }
        def mock_client_state_once(plugins, features, versions)
          pr     .should_receive(:read_client_plugins ).once.and_return plugins
          fr     .should_receive(:read_client_features).once.and_return features
          subject.should_receive(:read_client_versions).once.and_return versions
        end
        def stub_client_state(plugins, features, versions)
          pr.stub      read_client_plugins:  plugins
          fr.stub      read_client_feature:  features
          subject.stub read_client_versions: versions
        end
      EOB
    end

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

module DynamicFixtures
  def_fixture :new_cool_plugin do
    invoke_corvid! %(
      init --no-#{RUN_BUNDLE} --no-test-unit --no-test-spec
      init:plugin --no-#{RUN_BUNDLE}
      new:plugin cool
    )
    'Gemfile.lock'.should_not exist_as_file
    patch_corvid_gemfile
    patch_corvid_deps
    invoke_sh! 'bundle install --quiet'
    'Gemfile.lock'.should exist_as_file
  end
end

RSpec.configure do |config|
  config.include Corvid::PluginTestHelpers
  config.include GemfilePatching
  config.include TestHelpers
  config.include DynamicFixtures
end
