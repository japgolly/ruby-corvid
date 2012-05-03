# encoding: utf-8
require 'tmpdir'
require 'fileutils'

require 'hehe'

BOOTSTRAP_ALL= 'test/bootstrap/all.rb'
BOOTSTRAP_UNIT= 'test/bootstrap/unit.rb'

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
    src ||= "#{f}.tt"
    File.read(f).should == File.read("#{RAVEN_ROOT}/templates/#{src}")
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

    context 'should generate unit tests' do

      it("for the simplest case"){
        run 'unit_test hehe'
        files.should == [BOOTSTRAP_ALL, BOOTSTRAP_UNIT, 'test/unit/hehe_test.rb']
        file_should_match_template BOOTSTRAP_ALL
        file_should_match_template BOOTSTRAP_UNIT
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
        run 'unit_test /what/say::good.rb'
        files.should == [BOOTSTRAP_ALL, BOOTSTRAP_UNIT, 'test/unit/what/say/good_test.rb']
        file_should_match_template BOOTSTRAP_ALL
        file_should_match_template BOOTSTRAP_UNIT
        File.read(files.last).should == <<-EOB
# encoding: utf-8
require_relative '../../../bootstrap/unit'
require 'what/say/good'

class GoodTest < MiniTest::Unit::TestCase
  # TODO
end
        EOB
      }

      it("should preserve existing bootstraps"){
        FileUtils.mkdir_p File.dirname(BOOTSTRAP_ALL)
        File.write BOOTSTRAP_ALL, '123'
        File.write BOOTSTRAP_UNIT, 'abc'
        run 'unit_test hehe'
        files.should == [BOOTSTRAP_ALL, BOOTSTRAP_UNIT, 'test/unit/hehe_test.rb']
        File.read(BOOTSTRAP_ALL).should == '123'
        File.read(BOOTSTRAP_UNIT).should == 'abc'
      }
    end

  end # context
end

