# encoding: utf-8
require_relative '../../bootstrap/spec'
require 'corvid/generator/update'
require 'corvid/builtin/generator/init_corvid'
require 'helpers/fixture-upgrading'
require 'corvid/plugin'
require 'corvid/feature'
require 'corvid/builtin/test/resource_patch_tests'

describe Corvid::Generator::Update do

  add_generator_lets

  def mock_plugin(name, latest_version)
    p1= stub(name).tap{|p| p.stub name: name }
    rpm1= Corvid::ResPatchManager.new
    rpm1.stub latest_version: latest_version
    subject.stub(:rpm_for).with(p1).and_return(rpm1)
    pr.register p1
    p1
  end

  describe '#action_context_for_template2_au' do
    def test(*args)
      described_class.new.send :action_context_for_template2_au, *args
    end

    it("provides methods for given args"){
      d= test args: {str: 'good', num: 666}
      d.str.should == 'good'
      d.num.should == 666
    }

    context "when a generator is referenced" do
      it("loads the generator"){
        test generator: {require: 'corvid/plugin', class: described_class.to_s}
        expect { test generator: {require: 'omg_bru'*7} }.to raise_error LoadError
      }

      class FakeGenerator
        def initialize(*) end
        def num; 357 end
        def dyn; num * 100 end
      end

      it("delegates to an instance of the generator"){
        d= test generator: {class: FakeGenerator.to_s}
        d.num.should == 357
        d.dyn.should == 35700
      }

      it("overrides generator methods with args"){
        d= test generator: {class: FakeGenerator.to_s}, args: {num: 9}
        d.num.should == 9
      }

      it("generator methods access overriden methods too"){
        d= test generator: {class: FakeGenerator.to_s}, args: {num: 9}
        d.dyn.should == 900
      }
    end
  end

  describe '#update_loose_templates_for_template2!' do
    run_each_in_empty_dir

    class FakeGen < ::Corvid::Generator::Base
      desc 'make', ''
      def make; with_resources(plugin,1){ template2 '%name%.txt.tt' } end
      private
      def name; 'Happy' end
      def age; name.size end
    end

    let(:rpm){
      Corvid::ResPatchManager.new("#{Fixtures::FIXTURE_ROOT}/auto_update-templates")
      .tap{|rpm| rpm.patch_cmd += ' --quiet' }
    }

    it("should update templates specified in template manifest"){
      # Deploy template at v1
      fg= quiet_generator FakeGen
      fg.stub rpm_for: rpm, plugin: stub(name: 'p1')
      fg.make

      # Verify
      'Happy.txt'.should be_file_with_content /My name is Happy\./, /I'm 5 old/
      'Happy.txt'.should_not be_file_with_content /Bye/

      # Update to v3
      rpm.with_resource_versions 1, 3 do
        subject.send :update_loose_templates_for_template2!, rpm, 1, 3, 'bob', [{
          filename: '%name%.txt.tt',
          args: {name: 'Happy'},
          generator: {class: FakeGen.to_s},
        }]
      end

      # Verify
      'Happy.txt'.should be_file_with_content /My name is Happy!/, /I'm 5 years old/, /Bye/
    }
  end

  describe '#extract_deployable_files' do
    %w[
      copy_file
      copy_file_unless_exists
      copy_executable
    ].each do |keyword|
      it("should understand #{keyword}"){
        filename= "xxx.#$$"
        c= "def install\n  #{keyword} '#{filename}'\nend"
        subject.send(:extract_deployable_files, c, 'a',1).should == [filename]
      }
    end
    it("should ignore commands it doesn't recognize"){
      c= "def install\n  what_the_hell 'filename'\nend"
      subject.send(:extract_deployable_files, c, 'a',1).should == []
    }
    it("should parse commands on the same line"){
      c= "def install(); copy_file 'f1'; copy_file 'f2'; end"
      subject.send(:extract_deployable_files, c, 'a',1).should == %w[f1 f2]
    }
  end

  describe 'update:all' do
    def test(*expected)
      subject.instance_eval "@u= []; def update!(*a); @u<< a; end"
      subject.all
      subject.instance_variable_get(:@u).should equal_array expected
    end

    it("updates all installed features of installed plugins"){
      subject.stub read_client_versions: {'p1'=>2,'p2'=>4}
      fr.stub read_client_features: %w[p1:1a p1:1c p2:2a p2:2b]
      p1= mock_plugin 'p1', 6
      p2= mock_plugin 'p2', 7
      test [p1, 2, 6, %w[1a 1c]], [p2, 4, 7, %w[2a 2b]]
    }

    it("does nothing for up-to-date plugins"){
      subject.stub read_client_versions: {'p1'=>2,'p2'=>4}
      fr.stub read_client_features: %w[p1:1a p1:1c p2:2a p2:2b]
      p1= mock_plugin 'p1', 2
      p2= mock_plugin 'p2', 7
      test [p2, 4, 7, %w[2a 2b]]
    }

    it("does nothing when features are installed without a versions file"){
      subject.stub read_client_versions: nil
      fr.stub read_client_features: %w[p1:1a p1:1c]
      p1= mock_plugin 'p1', 6
      test
    }

    it("does nothing for plugins that dont have an installed version yet"){
      subject.stub read_client_versions: {'p2'=>4}
      fr.stub read_client_features: %w[p1:1a p1:1c p2:2a p2:2b]
      p1= mock_plugin 'p1', 6
      p2= mock_plugin 'p2', 7
      test [p2, 4, 7, %w[2a 2b]]
    }
  end

  describe '#update(plugin_filter)' do
    def test(plugin_filter, *expected)
      subject.instance_eval "@u= []; def update!(*a); @u<< a; end"
      subject.update(plugin_filter)
      subject.instance_variable_get(:@u).should equal_array expected
    end

    it("updates installed plugins matching given filter name"){
      subject.stub read_client_versions: {'p1'=>2,'p2'=>4}
      fr.stub read_client_features: %w[p1:1a p1:1c p2:2a p2:2b]
      p1= mock_plugin 'p1', 6
      p2= mock_plugin 'p2', 7
      test p1.name, [p1, 2, 6, %w[1a 1c]]
      test p2.name, [p2, 4, 7, %w[2a 2b]]
    }

    it("does nothing when plugin matching filter doesnt have an installed version yet"){
      subject.stub read_client_versions: {'p2'=>4}
      fr.stub read_client_features: %w[p1:1a p1:1c p2:2a p2:2b]
      p1= mock_plugin 'p1', 6
      p2= mock_plugin 'p2', 7
      test p1.name
    }
  end

  #---------------------------------------------------------------------------------------------------------------------

  describe 'Real Updating With Sample Resources', :slow do
    include Fixtures::Upgrading

    run_all_in_empty_dir {
      prepare_res_patches
      prepare_base_dirs do |ver|
        run_generator Corvid::Builtin::Generator::InitCorvid, "init --test-unit --no-test-spec"
        'Gemfile'.should_not exist_as_a_file # Make sure it's not using real res-patches
        assert_installation ver, ver
      end
    }

    def run_update_task
      run_generator Corvid::Generator::Update, 'all'
    end

    context 'corvid not installed' do
      run_each_in_empty_dir

      it("should refuse to update"){
        g= quiet_generator(Corvid::Generator::Update)
        subject.should_not_receive :update!
        subject.all
        get_files().should be_empty
      }
    end

    # not installed               - Done
    # up-to-date
    #      - without local mods   - Done
    #      - with local mods      - Done
    # out-of-date
    #      - without local mods   - Ignore
    #      - with local mods
    #        - non-conflicting    - Done
    #        - mergable           - Done
    #        - non-mergable       - Ignore

    def self.test_update_capability(max_ver)
      1.upto(max_ver - 1) do |inst_ver|
        eval <<-EOB
          context 'clean upgrading from v#{inst_ver}' do
            run_all_in_sandbox_copy_of(#{inst_ver}) do
              File.write @ignore_file= 'local.txt', @ignore_msg= 'leave me alone'
              run_update_task
            end

            it("should update from v#{inst_ver}->v#{max_ver}"){
              assert_installation #{max_ver}, #{max_ver}
            }
            it("should update the client's version number"){
              Corvid::Generator::Base.new.read_client_versions.should == {'corvid'=>#{max_ver}}
            }
            it("should ignore non-corvid files in the client dir"){
              @ignore_file.should exist_as_file
              File.read(@ignore_file).should == @ignore_msg
            }
          end
        EOB
      end
      eval <<-EOB
        context 'upgrading when client is up-to-date' do
          run_all_in_sandbox_copy_of(#{max_ver}) do
            @files_before= get_dir_entries()
            File.write 'corvid.A', 'whatever'
            run_update_task
          end

          it("should not change dirty files"){ File.read('corvid.A').should == 'whatever' }
          it("should not change up-to-date files"){ assert_installation #{max_ver}, #{max_ver}, %w[corvid.A] }
          it("should not change add or remove any files"){ get_dir_entries().should == @files_before }
        end
      EOB
    end

    context 'latest version available in corvid is v1' do
      run_all_with_corvid_resources_version 1
      test_update_capability 1
    end

    context 'latest version available in corvid is v2' do
      run_all_with_corvid_resources_version 2
      test_update_capability 2
    end

    context 'latest version available in corvid is v3' do
      run_all_with_corvid_resources_version 3
      test_update_capability 3
    end

    context 'latest version available in corvid is v4' do
      run_all_with_corvid_resources_version 4
      test_update_capability 4

      context 'dirty upgrading' do
        run_all_in_sandbox_copy_of(1) do
          File.write 'corvid.A', "--- sweet ---\ncorvid A made in v1\n"
          run_update_task
        end
        it("should patch dirty files"){
          File.read('corvid.A').should == "--- sweet ---\ncorvid A made in v1\nand in v2\nupdated in v3\n"
        }
        it("should update other files normally"){
          assert_installation 4, 4, %w[corvid.A]
        }
        it("should update the client's version number"){
          Corvid::Generator::Base.new.read_client_versions.should == {'corvid'=>4}
        }
      end
    end

    it("should check feature installer's requirements before upgrading"){
      @rpms= {'corvid' => @rpm_at_ver[5]}
      with_sandbox_copy_of(4) {
        # Try with unmet requirements
        expect{ run_update_task }.to raise_error ::Corvid::RequirementValidator::UnsatisfiedRequirementsError
        assert_installation 4, 4

        # Satisfy requirement and try again
        add_feature! 'corvid:whatever'
        run_update_task
        assert_installation 5, 5
      }
    }
  end
end

#-----------------------------------------------------------------------------------------------------------------------

class AutoUpdateTemplatesPluginFeature < Corvid::Feature
  since_ver 1
end
class AutoUpdateTemplatesPlugin < Corvid::Plugin
  name 'fake'
  resources_path "#{Fixtures::FIXTURE_ROOT}/auto_update-templates"
  feature_manifest ({
    'template2' => [nil,AutoUpdateTemplatesPluginFeature.to_s]
  })
end

describe AutoUpdateTemplatesPlugin do
  include Corvid::Builtin::ResourcePatchTests
  include_feature_update_install_tests
end
