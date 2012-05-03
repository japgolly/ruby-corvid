# encoding: utf-8
require 'tmpdir'
require 'fileutils'

require 'hehe'

BOOTSTRAP_ALL= 'test/bootstrap/all.rb'
BOOTSTRAP_UNIT= 'test/bootstrap/unit.rb'
BOOTSTRAP_SPEC= 'test/bootstrap/spec.rb'

describe 'Generator' do
  def run(args)
    args= args.map(&:inspect).join ' ' if args.kind_of?(Array)
    cmd= %`"#{RAVEN_ROOT}/bin/raven" #{args}`
    r= `#{cmd}`
    #puts r
  end

  def files
    @files ||= Dir['**/*'].select{|f| ! File.directory? f}.sort
  end

  def file_should_match_template(f, src=nil)
    File.read(f).should == File.read("#{RAVEN_ROOT}/templates/#{src || f}")
  end

  context 'in a bare project' do

    around :each do |ex|
      Dir.mktmpdir {|dir|
        FileUtils.cp_r "#{RAVEN_ROOT}/test/data/bare", dir
        Dir.chdir "#{dir}/bare" do
          ex.run
        end
      }
    end

    context 'init:test:unit' do
      it("should initalise unit test support"){
        run 'init:test:unit'
        files.should == [BOOTSTRAP_ALL, BOOTSTRAP_UNIT]
        file_should_match_template BOOTSTRAP_ALL
        file_should_match_template BOOTSTRAP_UNIT
      }

      it("should preserve the common bootstrap"){
        FileUtils.mkdir_p File.dirname(BOOTSTRAP_ALL)
        File.write BOOTSTRAP_ALL, '123'
        run 'init:test:unit'
        files.should == [BOOTSTRAP_ALL, BOOTSTRAP_UNIT]
        File.read(BOOTSTRAP_ALL).should == '123'
        file_should_match_template BOOTSTRAP_UNIT
      }
    end # init:test:unit

    context 'init:test:spec' do
      it("should initalise spec test support"){
        run 'init:test:spec'
        files.should == [BOOTSTRAP_ALL, BOOTSTRAP_SPEC]
        file_should_match_template BOOTSTRAP_ALL
        file_should_match_template BOOTSTRAP_SPEC
      }

      it("should preserve the common bootstrap"){
        FileUtils.mkdir_p File.dirname(BOOTSTRAP_ALL)
        File.write BOOTSTRAP_ALL, '123'
        run 'init:test:spec'
        files.should == [BOOTSTRAP_ALL, BOOTSTRAP_SPEC]
        File.read(BOOTSTRAP_ALL).should == '123'
        file_should_match_template BOOTSTRAP_SPEC
      }
    end # init:test:spec

    context 'test:unit' do
      it("simplest case"){
        run 'test:unit hehe'
        files.should == ['test/unit/hehe_test.rb']
        File.read(files.last).should == <<-EOB
# encoding: utf-8
require_relative '../bootstrap/unit'
require 'hehe'

class HeheTest < MiniTest::Unit::TestCase
  # TODO
end
        EOB
      }

      it("with leading slash, subdir, module and file ext"){
        run 'test:unit /what/say::good.rb'
        files.should == ['test/unit/what/say/good_test.rb']
        File.read(files.last).should == <<-EOB
# encoding: utf-8
require_relative '../../../bootstrap/unit'
require 'what/say/good'

class GoodTest < MiniTest::Unit::TestCase
  # TODO
end
        EOB
      }
    end # test:unit

    context 'test:spec' do
      it("simplest case"){
        run 'test:spec hehe'
        files.should == ['test/spec/hehe_spec.rb']
        File.read(files.last).should == <<-EOB
# encoding: utf-8
require_relative '../bootstrap/spec'
require 'hehe'

describe Hehe do
  # TODO
end
        EOB
      }

      it("with leading slash, subdir, module and file ext"){
        run 'test:spec /what/say::good.rb'
        files.should == ['test/spec/what/say/good_spec.rb']
        File.read(files.last).should == <<-EOB
# encoding: utf-8
require_relative '../../../bootstrap/spec'
require 'what/say/good'

describe What::Say::Good do
  # TODO
end
        EOB
      }
    end # test:spec

  end
end

