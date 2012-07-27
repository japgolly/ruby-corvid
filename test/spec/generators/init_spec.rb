# encoding: utf-8
require_relative '../spec_helper'
require 'corvid/generators/init'
require 'corvid/res_patch_manager'
require 'yaml'

describe Corvid::Generator::Init do
  context 'init:project' do

    def assert_corvid_version_is_latest
      v= YAML.load_file('.corvid/version.yml')
      v.should be_kind_of(Fixnum)
      v.should == Corvid::ResPatchManager.new.get_latest_res_patch_version
    end

    context 'in an empty directory' do
      context 'base feature only' do
        run_all_in_empty_dir {
          run_generator described_class, "project --no-test-unit --no-test-spec"
        }
        it("should create Gemfile"){ 'Gemfile'.should exist_as_a_file }
        it("should store the resource version"){ assert_corvid_version_is_latest }
        it("should store the corvid feature"){ assert_corvid_features 'corvid' }
      end
      context 'with additional features' do
        run_all_in_empty_dir {
          run_generator described_class, "project --test-unit --test-spec"
        }
        it("should create Gemfile"){ 'Gemfile'.should exist_as_a_file }
        it("should store the resource version"){ assert_corvid_version_is_latest }
        it("should store the corvid and test features"){ assert_corvid_features %w[corvid test_unit test_spec] }
      end
    end

    it("should overwrite the resource version when it exists"){
      inside_empty_dir {
        Dir.mkdir '.corvid'
        File.write '.corvid/version.yml', '0'
        run_generator described_class, "project --no-test-unit --no-test-spec"
        assert_corvid_version_is_latest
      }
    }

  end
end

#-----------------------------------------------------------------------------------------------------------------------

describe Corvid::Generator::Init::Test do
  around :each do |ex|
    inside_fixture('bare'){ ex.run }
  end

  context 'init:test:unit' do
    it("should initalise unit test support"){
      run_generator described_class, "unit"
      test_bootstraps true, true, false
      Dir.exists?('test/unit').should == true
      assert_corvid_features %w[corvid test_unit]
    }

    it("should preserve the common bootstrap"){
      FileUtils.mkdir_p File.dirname(BOOTSTRAP_ALL)
      File.write BOOTSTRAP_ALL, '123'
      run_generator described_class, "unit"
      File.read(BOOTSTRAP_ALL).should == '123'
      test_bootstraps nil, true, false
      Dir.exists?('test/unit').should == true
    }
  end # init:test:unit

  context 'init:test:spec' do
    it("should initalise spec test support"){
      run_generator described_class, "spec"
      test_bootstraps true, false, true
      Dir.exists?('test/spec').should == true
      assert_corvid_features %w[corvid test_spec]
    }

    it("should preserve the common bootstrap"){
      FileUtils.mkdir_p File.dirname(BOOTSTRAP_ALL)
      File.write BOOTSTRAP_ALL, '123'
      run_generator described_class, "spec"
      File.read(BOOTSTRAP_ALL).should == '123'
      test_bootstraps nil, false, true
      Dir.exists?('test/spec').should == true
    }
  end # init:test:spec

  def test_bootstraps(all, unit, spec)
    test_bootstrap BOOTSTRAP_ALL,  all,  true,  false, false unless all.nil?
    test_bootstrap BOOTSTRAP_UNIT, unit, false, true,  false unless unit.nil?
    test_bootstrap BOOTSTRAP_SPEC, spec, false, false, true  unless spec.nil?
  end

  def test_bootstrap(file, expected, all, unit, spec)
    if expected
      file.should exist_as_a_file
      c= File.read(file)
      c.send all  ? :should : :should_not, include('corvid/test/bootstrap/all')
      c.send unit ? :should : :should_not, include('unit')
      c.send spec ? :should : :should_not, include('spec')
    else
      file.should_not exist_as_a_file
    end
  end
end

#-----------------------------------------------------------------------------------------------------------------------

describe 'Installing features' do

  def fixture_dir(ver)
    "#{CORVID_ROOT}/test/fixtures/upgrading/r#{ver}"
  end

  def create_patches(upto_version)
    # Create res-patch dir
    res_dir= "res_patches_when_#{upto_version}_was_the_latest"
    Dir.mkdir res_dir

    # Create first patch
    rpm= Corvid::ResPatchManager.new("#{Dir.pwd}/#{res_dir}")
    Dir.mkdir 'empty' unless Dir.exists?('empty')
    rpm.create_res_patch 'empty', fixture_dir(1)
    get_files(res_dir).should == %w[00001.patch]

    # Create subsequent patches
    2.upto(upto_version) do |v|
      rpm.create_res_patch fixture_dir(v-1), fixture_dir(v)
      get_files(res_dir).size.should == v
    end

    rpm
  end

  def with_sandbox_copy_of(inst_ver)
    FileUtils.rm_rf 'sandbox'
    FileUtils.cp_r "base.#{inst_ver}", 'sandbox'
    Dir.chdir('sandbox') do
      yield
    end
  end

  def assert_installation(corvid_ver, test_ver)
    assert_file "corvid.A", 1, corvid_ver
    assert_file "corvid.B", 2, corvid_ver
    assert_file "corvid.C", 3, corvid_ver
    "lib.1".send corvid_ver >= 1 ? :should : :should_not, exist_as_dir
    "lib.2".send corvid_ver >= 2 ? :should : :should_not, exist_as_dir
    "lib.3".send corvid_ver >= 3 ? :should : :should_not, exist_as_dir

    assert_file "test.A", 1, test_ver
    assert_file "test.B", 2, test_ver
    assert_file "test.C", 3, test_ver
    "test.1".send test_ver >= 1 ? :should : :should_not, exist_as_dir
    "test.2".send test_ver >= 2 ? :should : :should_not, exist_as_dir
    "test.3".send test_ver >= 3 ? :should : :should_not, exist_as_dir
  end

  def assert_file(file, active_ver_range, ver)
    expected= case active_ver_range
              when Range then active_ver_range.member?(ver)
              when Fixnum then ver >= active_ver_range
              else raise "What? #{active_ver_range.inspect}"
              end
    if expected
      file.should exist_as_a_file
      File.read(file).should == File.read("#{fixture_dir ver}/#{file}")
    else
      file.should_not exist_as_a_file
    end
  end

  #----------------------------------------------------------------
  # Create res-patches and fake installations before starting tests
  run_all_in_empty_dir {

    # Turn the r?? fixture directories into res-patches
    @rpms= [nil]
    @rpms<< create_patches(1)
    @rpms<< create_patches(2)
    @rpms<< create_patches(3)

    # Create installations of the corvid feature at various versions
    1.upto(@rpms.size - 1) do |i|
      dir= "base.#{i}"
      Dir.mkdir dir
      Dir.chdir(dir){
        @rpm= @rpms[i]
        run_generator Corvid::Generator::Init, "project --no-test-unit --no-test-spec"
        'Gemfile'.should_not exist_as_a_file # Make sure it's not using real res-patches
        assert_installation i, 0
      }
    end
  }

  def self.test_feature_installation(max_version_available)
    1.upto(max_version_available) do |inst_ver|
      eval <<-EOB
        context 'feature installed on top of v#{inst_ver}' do
          before :all do
            with_sandbox_copy_of(#{inst_ver}) do
              run_generator Corvid::Generator::Init::Test, 'unit'
              @features= Corvid::Generator::Base.new.get_installed_features
            end
          end
          around :each do |ex|
            Dir.chdir('sandbox'){ ex.call }
          end
          it("should install v#{inst_ver} of the feature"){
            assert_installation #{inst_ver}, #{inst_ver}
          }
          it("should preserve the existing features in the registry"){
            @features.should include('corvid')
          }
          it("should register the new feature"){
            @features.should include('test_unit')
          }
        end
      EOB
    end
  end

  context 'latest version available in corvid is 1' do
    before(:all){ @rpm= @rpms[1] }
    after(:all){ @rpm= nil }
    test_feature_installation 1
  end

  context 'latest version available in corvid is 2' do
    before(:all){ @rpm= @rpms[2] }
    after(:all){ @rpm= nil }
    test_feature_installation 2

    it("should do nothing if feature already installed"){
      with_sandbox_copy_of(2) do
        f= YAML.load_file('.corvid/features.yml') + ['test_unit']
        File.write '.corvid/features.yml', f.to_yaml
        run_generator Corvid::Generator::Init::Test, 'unit'
        assert_installation 2, 0
      end
    }
  end

  context 'latest version available in corvid is 3' do
    before(:all){ @rpm= @rpms[3] }
    after(:all){ @rpm= nil }
    test_feature_installation 3
  end

  context 'Corvid not installed' do
    it("should refuse feature installation"){
      inside_empty_dir {
        expect {
          run_generator Corvid::Generator::Init::Test, 'unit'
        }.to raise_error
        get_files().should be_empty
      }
    }
  end
end
