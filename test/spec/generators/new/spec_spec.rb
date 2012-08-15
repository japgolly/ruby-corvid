# encoding: utf-8
require_relative '../../../spec_helper'
require 'corvid/generators/new/spec'

describe Corvid::Generator::NewSpec do
  around :each do |ex|
    inside_fixture('bare'){ ex.run }
  end

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
