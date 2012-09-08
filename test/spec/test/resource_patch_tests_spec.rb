# encoding: utf-8
require_relative '../../spec_helper'
require 'corvid/test/resource_patch_tests'

describe Corvid::ResourcePatchTests, :slow do
  include Corvid::ResourcePatchTests

  run_each_in_empty_dir

  before :each do
    @plugin= BUILTIN_PLUGIN.new
    Corvid::PluginRegistry.clear_cache.register @plugin
  end

  it("should fail when update() has an extra step that's not in install()"){
    @plugin.should_receive(:resources_path).at_least(:once).and_return "#{Fixtures::FIXTURE_ROOT}/invalid_res_patch-extra_update_step"
    expect{ test_feature_updates_match_install @plugin, 'corvid' }.to raise_error /wtfff/
  }

  it("should fail when update() is missing a step that's in install()"){
    @plugin.should_receive(:resources_path).at_least(:once).and_return "#{Fixtures::FIXTURE_ROOT}/invalid_res_patch-missing_update_step"
    expect{ test_feature_updates_match_install @plugin, 'corvid' }.to raise_error /wtfff/
  }
end
