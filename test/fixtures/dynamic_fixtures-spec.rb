require 'golly-utils/testing/dynamic_fixtures'

RSpec.configure do |config|
  config.include GollyUtils::Testing::DynamicFixtures
end

module GollyUtils::Testing::DynamicFixtures

  # TODO fixture 'bare' should go or at least be renamed
  def_fixture :bare do
    require 'corvid/res_patch_manager'
    Dir.mkdir '.corvid'
    add_plugin! BUILTIN_PLUGIN.new
    add_feature! 'corvid:corvid'
    add_version! 'corvid', Corvid::ResPatchManager.new.latest_version
  end

  def_fixture :corvid_only, dir_name: 'my_thing' do
    require 'corvid/builtin/generator/init_corvid'
    run_generator Corvid::Builtin::Generator::InitCorvid, "init --no-test-unit --no-test-spec"
  end

  def_fixture :corvid_then_test_unit do
    copy_dynamic_fixture :corvid_only
    require 'corvid/builtin/generator/init_test_unit'
    run_generator Corvid::Builtin::Generator::InitTestUnit, "unit"
  end

  def_fixture :corvid_then_test_spec do
    copy_dynamic_fixture :corvid_only
    require 'corvid/builtin/generator/init_test_spec'
    run_generator Corvid::Builtin::Generator::InitTestSpec, "spec"
  end

end
