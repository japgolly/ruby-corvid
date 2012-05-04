# encoding: utf-8

require_relative '../../lib/raven/environment'

require 'tmpdir'
require 'fileutils'

BOOTSTRAP_ALL= 'test/bootstrap/all.rb'
BOOTSTRAP_UNIT= 'test/bootstrap/unit.rb'
BOOTSTRAP_SPEC= 'test/bootstrap/spec.rb'

module TestHelpers
  def invoke_raven(args)
    args= args.map(&:inspect).join ' ' if args.kind_of?(Array)
    cmd= %`"#{RAVEN_ROOT}/bin/raven" #{args}`
    r= `#{cmd}`
    #puts r
  end

  def files
    @files ||= Dir['**/*'].select{|f| ! File.directory? f}.sort - %w[Gemfile Gemfile.lock]
  end

  def file_should_match_template(f, src=nil)
    File.read(f).should == File.read("#{RAVEN_ROOT}/templates/#{src || f}")
  end

  def inside_fixture(fixture_name)
    Dir.mktmpdir {|dir|
      FileUtils.cp_r "#{RAVEN_ROOT}/test/fixtures/#{fixture_name}", dir
      Dir.chdir "#{dir}/#{fixture_name}" do
        `sed -i 's|\.\./\.\./\.\.|#{RAVEN_ROOT}|g; s/0\.0\.1/#{Raven::VERSION}/' Gem*`
        yield
      end
    }
  end
end

RSpec.configure do |config|
  config.include TestHelpers
end

