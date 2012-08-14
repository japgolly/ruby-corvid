# encoding: utf-8
require_relative '../../spec_helper'
require 'corvid/test/resource_patch_tests'

describe Corvid::ResourcePatchTests do
  include Corvid::ResourcePatchTests
  use_resources_path BUILTIN_PLUGIN.new.resources_path

  run_each_in_empty_dir

  it("should fail when update() has an extra step that's not in install()"){
    @rpm= Corvid::ResPatchManager.new "#{Fixtures::FIXTURE_ROOT}/invalid_res_patch-extra_update_step"
    expect{ test_feature_updates_match_install 'corvid', 'corvid' }.to raise_error /wtfff/
  }

  it("should fail when update() is missing a step that's in install()"){
    @rpm= Corvid::ResPatchManager.new "#{Fixtures::FIXTURE_ROOT}/invalid_res_patch-missing_update_step"
    expect{ test_feature_updates_match_install 'corvid', 'corvid' }.to raise_error /wtfff/
  }
end
