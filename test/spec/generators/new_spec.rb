# encoding: utf-8
require_relative '../../spec_helper'
require 'corvid/generators/new'
require 'corvid/extension'

describe Corvid::Generator::New do
  describe 'new:plugin' do
    run_all_in_empty_dir {
      copy_fixture 'bare'
      run_generator described_class, 'plugin happy'
    }

    it("should create a plugin"){
      'lib/corvid/happy_plugin.rb'.should be_file_with_contents <<-EOB
require 'corvid/plugin'

class HappyPlugin < Corvid::Plugin

  require_path 'lib/corvid/happy_plugin'

  feature_manifest ({
  })

end
      EOB
    }
    it("should create a plugin test"){
      'test/spec/happy_plugin_spec.rb'.should be_file_with_contents <<-EOB
# encoding: utf-8
require_relative '../bootstrap/spec'
require 'corvid/test/resource_patch_tests'
require 'lib/corvid/happy_plugin'

describe HappyPlugin do
  include Corvid::ResourcePatchTests
  res_patch_dir "#\{APP_ROOT}/resources"

  include_feature_update_install_tests 'happy', HappyPlugin.new
end
      EOB
    }
  end
end

#-----------------------------------------------------------------------------------------------------------------------

describe Corvid::Generator::New::Plugin do
  describe 'new:plugin:feature' do
    context "with no client res-patches" do
      run_all_in_empty_dir {
        copy_fixture 'bare'
        run_generator Corvid::Generator::New, 'plugin big'
        run_generator described_class, 'feature small'
      }

      it("should declare the feature as being since_ver 1"){
        'lib/corvid/small_feature.rb'.should be_file_with_contents /since_ver 1/
      }
    end

    context "with 2 mock client res-patches" do
      run_all_in_empty_dir {
        copy_fixture 'bare'
        Dir.mkdir 'resources'
        File.write 'resources/00001.patch', ''
        File.write 'resources/00002.patch', ''
        run_generator Corvid::Generator::New, 'plugin big'
        run_generator described_class, 'feature small'
      }

      it("should create a feature"){
        'lib/corvid/small_feature.rb'.should be_file_with_contents(/class SmallFeature < Corvid::Feature/)
          .and(%r[require 'corvid/feature'])
      }

      it("should declare the feature as being since_ver 3"){
        'lib/corvid/small_feature.rb'.should be_file_with_contents /since_ver 3/
      }

      Corvid::Extension.callbacks.each do |ext_point|
        class_eval <<-EOB
          it("should include extension point in feature: #{ext_point}"){
            'lib/corvid/small_feature.rb'.should be_file_with_contents /#{ext_point}/
          }
        EOB
      end

      it("should create a feature installer"){
        'resources/latest/corvid-features/small.rb'.should be_file_with_contents /^install\s*{/
      }

      it("should add the feature to the plugin manifest"){
        'lib/corvid/big_plugin.rb'.should be_file_with_contents \
          /feature_manifest\s*\(\{\n\s+'small'\s*=>\s*\['corvid\/small_feature'\s*,\s*'::SmallFeature'\],\n/
      }

    end
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
      'test/unit/hehe_test.rb'.should be_file_with_contents <<-EOB
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
      'test/unit/what/say/good_test.rb'.should be_file_with_contents <<-EOB
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
      'test/spec/hehe_spec.rb'.should be_file_with_contents <<-EOB
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
      'test/spec/what/say/good_spec.rb'.should be_file_with_contents <<-EOB
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
