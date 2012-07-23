# encoding: utf-8

require_relative '../../lib/corvid/environment'

require 'tmpdir'
require 'fileutils'

RUN_BUNDLE= 'run_bundle'
BOOTSTRAP_ALL= 'test/bootstrap/all.rb'
BOOTSTRAP_UNIT= 'test/bootstrap/unit.rb'
BOOTSTRAP_SPEC= 'test/bootstrap/spec.rb'

module TestHelpers
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

  def file_should_match_template(f, src=nil)
    File.read(f).should == File.read("#{CORVID_ROOT}/templates/#{src || f}")
  end

  def inside_fixture(fixture_name, copy_templates=false)
    Dir.mktmpdir {|dir|
      FileUtils.cp_r "#{CORVID_ROOT}/templates/.", dir, dereference_root: true if copy_templates
      FileUtils.cp_r "#{CORVID_ROOT}/test/fixtures/#{fixture_name}/.", dir
      Dir.chdir dir do
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

end

RSpec.configure do |config|
  config.include TestHelpers
end

