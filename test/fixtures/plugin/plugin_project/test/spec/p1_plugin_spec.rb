# encoding: utf-8
require_relative '../bootstrap/spec'
require 'corvid/builtin/test/resource_patch_tests'
require 'plugin_project/p1_plugin'

describe PluginProject::P1Plugin do
  include Corvid::ResourcePatchTests

  include_resource_patch_tests

  include_feature_update_install_tests
end
