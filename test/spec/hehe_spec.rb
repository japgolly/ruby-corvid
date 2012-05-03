# encoding: utf-8
require 'tmpdir'
require 'fileutils'

require 'hehe'

describe 'Generator' do
  context 'in a bare project' do

    around :each do |ex|
      Dir.mktmpdir {|dir|
        FileUtils.cp_r "#{RAVEN_ROOT}/test/data/bare", dir
        Dir.chdir "#{dir}/bare" do
          ex.run
        end
      }
    end

    def run(args)
      #cmd= %`"#{RAVEN_ROOT}/bin/g" #{args.map(&:inspect).join ' '}`
      cmd= %`"#{RAVEN_ROOT}/bin/g" #{args}`
      r= `#{cmd}`
      puts r
    end

    def files
      @files ||= Dir['**/*'].select{|f| ! File.directory? f}.sort
    end

    def check_file(f, src=nil)
      src ||= "#{f}.tt"
      File.read(f).should == File.read("#{RAVEN_ROOT}/templates/#{src}")
    end

    def check_bootstrap_all
      check_file 'test/bootstrap/all.rb'
    end

    def check_bootstrap_unit
      check_file 'test/bootstrap/unit.rb'
    end

    context 'should generate unit tests' do

      it("for the simplest case"){
        run 'unit_test hehe'
        files.should == %w[test/bootstrap/all.rb test/bootstrap/unit.rb test/unit/hehe_test.rb]
        check_bootstrap_all
        check_bootstrap_unit
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
        files.should == %w[test/bootstrap/all.rb test/bootstrap/unit.rb test/unit/what/say/good_test.rb]
        check_bootstrap_all
        check_bootstrap_unit
        File.read(files.last).should == <<-EOB
# encoding: utf-8
require_relative '../../../bootstrap/unit'
require 'what/say/good'

class GoodTest < MiniTest::Unit::TestCase
  # TODO
end
        EOB
      }
    end

  end # context
end

