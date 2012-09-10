# encoding: utf-8
require_relative '../../bootstrap/spec'
require 'corvid/generators/template_vars'
require 'fileutils'

describe Corvid::Generator::TemplateVars do
  include described_class

  describe '#project_name' do
    run_each_in_empty_dir 'crazy'

    it("uses the directory name in an empty dir"){
      project_name.should == 'crazy'
    }

    it("uses the only subdir of lib"){
      FileUtils.mkdir_p 'lib/sweet/noise1'
      FileUtils.mkdir_p 'lib/sweet/noise2'
      File.write 'lib/noise', ''
      project_name.should == 'sweet'
    }

    it("ignores subdirs of lib when there is more than one"){
      Dir.mkdir 'lib'
      Dir.mkdir 'lib/hey'
      Dir.mkdir 'lib/mate'
      project_name.should_not == 'hey'
      project_name.should_not == 'mate'
    }

    it("extracts from the gemspec filename"){
      File.write 'whatever.gemspec', ''
      project_name.should == 'whatever'
    }

    it("ignores gemspec files when there is more than one"){
      File.write 'whatever.gemspec', ''
      File.write 'what_is_this.gemspec', ''
      project_name.should_not == 'whatever'
      project_name.should_not == 'what_is_this'
    }
  end
end
