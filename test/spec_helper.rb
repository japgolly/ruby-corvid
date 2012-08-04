# encoding: utf-8

STDIN.close

require_relative '../lib/corvid/environment'
require 'golly-utils/testing/rspec/files'
require 'golly-utils/testing/rspec/arrays'
require 'tmpdir'
require 'fileutils'

RUN_BUNDLE= 'run_bundle'
BOOTSTRAP_ALL= 'test/bootstrap/all.rb'
BOOTSTRAP_UNIT= 'test/bootstrap/unit.rb'
BOOTSTRAP_SPEC= 'test/bootstrap/spec.rb'

# Add test/ to lib path
$:<< "#{CORVID_ROOT}/test"

module Fixtures
  FIXTURE_ROOT= "#{CORVID_ROOT}/test/fixtures"
end

module TestHelpers

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
    cmd= %`"#{CORVID_ROOT}/bin/corvid" #{args}`
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

  def files(force=false)
    @files= nil if force
    @files ||= Dir['**/*'].select{|f| ! File.directory? f}.sort
  end
  def dirs(force=false)
    @dirs= nil if force
    @dirs ||= Dir['**/*'].select{|f| File.directory? f}.sort
  end

  def inside_fixture(fixture_name)
    Dir.mktmpdir {|dir|
      FileUtils.cp_r "#{CORVID_ROOT}/test/fixtures/#{fixture_name}", dir
      Dir.chdir "#{dir}/#{fixture_name}" do
        patch_corvid_gemfile
        yield
      end
    }
  end

  def patch_corvid_gemfile
    files= %w[Gemfile .corvid/Gemfile]
    files.select!{|f| File.exists? f}
    unless files.empty?
      `perl -pi -e '
         s|^\\s*(gem\\s+.corvid.)\\s*(?:,\\s*path.*)?$|\\1, path: "#{CORVID_ROOT}"|
       ' #{files.join ' '}`
      raise 'patch failed' unless $?.success?
    end
    true
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

  def generator_config(quiet)
    # Quiet stdout - how the hell else are you supposed to do this???
    config= {}
    config[:shell] ||= Thor::Base.shell.new
    if quiet
      config[:shell].instance_eval 'def say(*) end'
      config[:shell].instance_eval 'def quiet?; true; end'
      #config[:shell].instance_variable_set :@mute, true
    end
    config
  end

  def quiet_generator(generator_class)
    config= generator_config(true)
    g= generator_class.new([], [], config)
    decorate_generator g
  end

  def decorate_generator(g)
    # Use a test res-patch manager if available
    g.rpm= @rpm if @rpm
    g
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

RSpec.configure do |config|
  config.include TestHelpers
end