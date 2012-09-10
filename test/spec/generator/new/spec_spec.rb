# encoding: utf-8
require_relative '../../../bootstrap/spec'
require 'corvid/generator/new/spec'

describe Corvid::Generator::NewSpec do
  run_each_in_dynamic_fixture :bare
  before(:each){ add_feature! 'corvid:test_spec' }

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
  end
end
