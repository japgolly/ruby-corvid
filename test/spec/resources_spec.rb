# encoding: utf-8
require_relative '../spec_helper'
require 'corvid/test/resource_patch_tests'

describe "Actual Resources" do
  include Corvid::ResourcePatchTests
  res_patch_dir Corvid::ResPatchManager.default_res_patch_dir

  include_patch_validity_tests

  include_feature_update_install_tests BUILTIN_FEATURES
end
