# encoding: utf-8
require_relative '../../spec_helper'
require 'corvid/generators/new'

describe Corvid::Generator::New do
  describe 'new:plugin' do
    run_all_in_empty_dir {
      copy_fixture 'bare'
      run_generator described_class, 'plugin happy'
    }

    it("should create a plugin"){
      # TODO create be_file_with_contents(str|regex).and().and()
      'lib/corvid/happy_plugin.rb'.should exist_as_file
      File.read('lib/corvid/happy_plugin.rb').should == <<-EOB
require 'corvid/plugin'

class HappyPlugin < Corvid::Plugin

  require_path 'lib/corvid/happy_plugin'

  feature_manifest ({
  })

end
      EOB
    }
    it("should create a plugin"){
      # TODO create be_file_with_contents(str|regex).and().and()
      'test/spec/happy_plugin_spec.rb'.should exist_as_file
      File.read('test/spec/happy_plugin_spec.rb').should == <<-EOB
# encoding: utf-8
require_relative '../bootstrap/spec'
require 'corvid/test/resource_patch_tests'
require 'lib/corvid/happy_plugin'

describe HappyPlugin do
  include Corvid::ResourcePatchTests
  res_patch_dir "#\{APP_ROOT}/resources"

  include_feature_update_install_tests HappyPlugin.new
end
      EOB
    }
  end
end

#-----------------------------------------------------------------------------------------------------------------------

describe Corvid::Generator::New::Test do
  around :each do |ex|
    inside_fixture('bare'){ ex.run }
  end

  describe 'new:test:unit' do
    it("simplest case"){
      run_generator described_class, 'unit hehe'
      File.read('test/unit/hehe_test.rb').should == <<-EOB
# encoding: utf-8
require_relative '../bootstrap/unit'
require 'hehe'

class HeheTest < MiniTest::Unit::TestCase
  # T\ODO
end
      EOB
    }

    it("with leading slash, subdir, module and file ext"){
      run_generator described_class, 'unit /what/say::good.rb'
      File.read('test/unit/what/say/good_test.rb').should == <<-EOB
# encoding: utf-8
require_relative '../../../bootstrap/unit'
require 'what/say/good'

class GoodTest < MiniTest::Unit::TestCase
  # T\ODO
end
      EOB
    }
  end # new:test:unit

  describe 'new:test:spec' do
    it("simplest case"){
      run_generator described_class, 'spec hehe'
      File.read('test/spec/hehe_spec.rb').should == <<-EOB
# encoding: utf-8
require_relative '../bootstrap/spec'
require 'hehe'

describe Hehe do
  # T\ODO
end
      EOB
    }

    it("with leading slash, subdir, module and file ext"){
      run_generator described_class, 'spec /what/say::good.rb'
      File.read('test/spec/what/say/good_spec.rb').should == <<-EOB
# encoding: utf-8
require_relative '../../../bootstrap/spec'
require 'what/say/good'

describe What::Say::Good do
  # T\ODO
end
      EOB
    }
  end # new:test:spec

end
