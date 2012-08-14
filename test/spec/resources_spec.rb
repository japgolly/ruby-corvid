# encoding: utf-8
require_relative '../spec_helper'
require 'corvid/test/resource_patch_tests'

describe "Actual Resources" do
  include Corvid::ResourcePatchTests
  use_resources_path BUILTIN_PLUGIN.new.resources_path

  include_patch_validity_tests {|dir|
    "#{dir}/1/Gemfile".should exist_as_file
  }

  include_feature_update_install_tests 'corvid', BUILTIN_PLUGIN.new
end
