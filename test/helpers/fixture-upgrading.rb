require 'corvid/res_patch_manager'

module Fixtures::Upgrading
  MAX_VER= 4

  def fixture_dir(ver)
    "#{Fixtures::FIXTURE_ROOT}/upgrading/r#{ver}"
  end

  # Turn the r?? fixture directories into res-patches
  def prepare_res_patches
    @rpms= [nil]
    1.upto(MAX_VER) do |v|
      @rpms<< create_patches(v)
    end
  end

  # Create client installations at various versions.
  #
  # @yield [Fixnum] latest_ver The latest version available to the mock Corvid res-patch set.
  def prepare_base_dirs
    1.upto(MAX_VER) do |i|
      dir= "base.#{i}"
      Dir.mkdir dir
      Dir.chdir(dir){
        @rpm= @rpms[i]
        yield i
        @rpm= nil
      }
    end
  end

  def with_sandbox_copy_of(inst_ver)
    FileUtils.rm_rf 'sandbox'
    FileUtils.cp_r "base.#{inst_ver}", 'sandbox'
    Dir.chdir('sandbox') do
      yield
    end
  end

  def assert_installation(corvid_ver, test_ver, ignore_list=[])
    assert_file "corvid.A", 1, corvid_ver, false, ignore_list
    assert_file "corvid.B", 2..3, corvid_ver, false, ignore_list
    assert_file "corvid.C", 3, corvid_ver, true, ignore_list
    "lib.1".send corvid_ver >= 1 ? :should : :should_not, exist_as_dir
    "lib.2".send corvid_ver >= 2 ? :should : :should_not, exist_as_dir
    "lib.3".send corvid_ver >= 3 ? :should : :should_not, exist_as_dir

    assert_file "test.A", 1, test_ver, false, ignore_list
    assert_file "test.B", 2..3, test_ver, false, ignore_list
    assert_file "test.C", 3, test_ver, true, ignore_list
    "test.1".send test_ver >= 1 ? :should : :should_not, exist_as_dir
    "test.2".send test_ver >= 2 ? :should : :should_not, exist_as_dir
    "test.3".send test_ver >= 3 ? :should : :should_not, exist_as_dir
  end

  def assert_file(file, active_ver_range, ver, executable=false, ignore_list=[])
    return if ignore_list.include?(file)
    expected= case active_ver_range
              when Range then active_ver_range.member?(ver)
              when Fixnum then ver >= active_ver_range
              else raise "What? #{active_ver_range.inspect}"
              end
    if expected
      file.should exist_as_a_file
      File.read(file).should == File.read("#{fixture_dir ver}/#{file}")
      File.executable?(file).should == executable
    else
      file.should_not exist_as_a_file
    end
  end

  # @!visibility private
  def self.included(base)
    base.extend ClassMethods
  end
  module ClassMethods

    def run_all_with_corvid_resources_version(ver)
      eval <<-EOB
        before(:all){ raise "Invalid version: #{ver}" unless @rpm= @rpms[#{ver}] }
        after(:all){ @rpm= nil }
      EOB
    end

    def run_all_in_sandbox_copy_of(ver, &block)
      before :all do
        with_sandbox_copy_of(ver) do
          instance_exec &block if block
        end
      end
      around :each do |ex|
        Dir.chdir('sandbox'){ ex.call }
      end
    end

  end # ClassMethods

  private

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
end
