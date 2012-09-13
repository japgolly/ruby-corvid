# encoding: utf-8
require_relative '../../bootstrap/spec'
require 'corvid/generator/base'

describe Corvid::Generator::Base do
  add_generator_lets

  def source_root; $corvid_global_thor_source_root; end

  class X < Corvid::Generator::Base
    no_tasks {
      public :rpm, :with_latest_resources
    }
  end
  class Y < Corvid::Generator::Base
    no_tasks {
      public :rpm, :with_latest_resources
      attr_writer :rpm
    }
  end

  describe '#with_latest_resources' do
    let(:plugin){ BUILTIN_PLUGIN.new }
    let(:x){ X.new }

    it("should provide resources"){
      x.rpm_for(plugin).should_not be_nil
      x.rpm_for(plugin).should_receive(:with_resources).once
      x.with_latest_resources(plugin) {}
    }

    it("should reuse an existing res-patch deployment"){
      made_y= false
      x.with_latest_resources(plugin) {
        x.rpm.should_not be_nil
        x.rpm.should_not_receive(:with_resources)
        Y.new.with_latest_resources(plugin) {
          made_y= true
        }
      }
      made_y.should == true
    }

    it("should reset the templates directory when done"){
      made_deepest= false
      X.new.with_latest_resources(plugin) {
        source_root.should_not be_nil
        X.new.with_latest_resources(plugin) {
          source_root.should_not be_nil
          made_deepest= true
        }
        source_root.should_not be_nil
      }
      made_deepest.should == true
      source_root.should be_nil
    }
  end

  describe '#feature_installer' do
    def installer_for(code)
      subject.stub feature_installer_file: 'as.rb'
      File.stub exist?: true
      File.should_receive(:read).once.and_return(code)
      subject.send(:feature_installer!,'dir','mock')
    end

    it("should allow declarative definition of install"){
      f= installer_for "install{ copy_file 'hehe'; 123 }"
      subject.should_receive(:copy_file).with('hehe').once
      f.install().should == 123
    }
    it("should allow declarative definition of update"){
      f= installer_for "update{ copy_file 'hehe2'; :no }"
      subject.should_receive(:copy_file).with('hehe2').once
      f.update().should == :no
    }
    it("should pass a version argument to update"){
      f= installer_for "update{|v| v*v }"
      f.update(3).should == 9
    }
    it("should allow declarative definition of values (as opposed to blocks)"){
      stub_const "#{Corvid::Generator::Base}::FEATURE_INSTALLER_VALUES_DEFS", %w[since_ver]
      f= installer_for "since_ver 2"
      f.since_ver().should == 2
    }
    it("should fail when no block passed to install"){
      expect { installer_for "install" }.to raise_error
    }
    it("should respond_to? provided values only"){
      f= installer_for "install{ 2 }"
      f.respond_to?(:install).should == true
      f.respond_to?(:update).should == false
    }
  end

  describe "#install_feature" do
    it("should fail if client resource version is prior to first feature version"){
      stub_client_state %w[a], [], {'a'=>3}
      f= mock 'feature b'
      f.should_receive(:since_ver).at_least(:once).and_return(4)
      fr.should_receive(:instance_for).with('a:b').once.and_return(f)
      pr.should_receive(:instance_for).with('a').once.and_return(stub name: 'a')
      subject.should_not_receive :with_resources
      expect{
        subject.send :install_feature, 'a', 'b'
      }.to raise_error /update/
    }

    it("should do nothing if feature already installed"){
      stub_client_state %w[a], %w[a:b], {'a'=>3}
      pr.should_receive(:instance_for).with('a').once.and_return(stub name: 'a')
      subject.should_not_receive :with_resources
      subject.send :install_feature, 'a', 'b'
    }

    it("should fail if plugin isn't already installed"){
      stub_client_state %w[a], %w[a:af], {'a'=>3}
      expect{
        subject.send :install_feature, BUILTIN_PLUGIN.new, 'whatever'
      }.to raise_error /plugin is not installed/
    }

    it("should validate requirements in the feature class"){
      stub_client_state %w[a], nil, nil
      p= stub name: 'a'
      pr.should_receive(:instance_for).with('a').once.and_return(p)
      f= stub requirements: 'x'
      fr.should_receive(:instance_for).with('a:b').once.and_return(f)
      subject.stub feature_installer!: mock('fi')
      subject.stub(:with_resources).and_yield(7)

      rv= mock 'rv'
      subject.should_receive(:new_requirement_validator).once.and_return(rv)
      rv.stub :add
      rv.should_receive(:add).with('x')
      rv.should_receive(:validate!).once.and_raise(Corvid::RequirementValidator::UnsatisfiedRequirementsError)
      subject.should_not_receive :add_feature
      expect{ subject.send :install_feature, 'a', 'b' }.to raise_error Corvid::RequirementValidator::UnsatisfiedRequirementsError
    }

    class FakeFeatureInstaller
      def requirements; 'y' end
    end
    it("should validate requirements in the feature installer"){
      stub_client_state %w[a], nil, nil
      p= stub name: 'a'
      pr.should_receive(:instance_for).with('a').once.and_return(p)
      f= stub requirements: nil
      fr.should_receive(:instance_for).with('a:b').once.and_return(f)
      subject.should_receive(:feature_installer!).with('b').once.and_return(FakeFeatureInstaller.new)
      subject.should_receive(:with_resources).with(p,:latest).once.and_yield(7)

      rv= mock 'rv'
      subject.should_receive(:new_requirement_validator).once.and_return(rv)
      rv.stub :add
      rv.should_receive(:add).once.with('y')
      rv.should_receive(:validate!).once.and_raise(Corvid::RequirementValidator::UnsatisfiedRequirementsError)
      subject.should_not_receive :add_feature
      expect{ subject.send :install_feature, 'a', 'b' }.to raise_error Corvid::RequirementValidator::UnsatisfiedRequirementsError
    }
  end

  describe '#add_plugin' do
    run_all_in_empty_dir { Dir.mkdir '.corvid' }
    before(:each){ File.delete CONST::PLUGINS_FILE if File.exists? CONST::PLUGINS_FILE }

    it("should create the plugins file if it doesnt exist yet"){
      subject.send :add_plugin, BUILTIN_PLUGIN.new
      assert_plugins_installed BUILTIN_PLUGIN_DETAILS
    }

    it("should add new plugins to the plugin file"){
      before= {'xxx'=>{path: 'xpath', class: 'X'}}.freeze
      File.write CONST::PLUGINS_FILE, before.to_yaml
      subject.send :add_plugin, BUILTIN_PLUGIN.new
      assert_plugins_installed before.merge BUILTIN_PLUGIN_DETAILS
    }

    it("should replace existing plugin details if they differ") {
      File.write CONST::PLUGINS_FILE, {'corvid'=>{path: 'xpath', class: 'X'}}.to_yaml
      subject.send :add_plugin, BUILTIN_PLUGIN.new
      assert_plugins_installed BUILTIN_PLUGIN_DETAILS
    }
  end

  describe '#install plugin' do
    it("should do nothing if plugin already installed"){
      pr.should_receive(:instance_for).with('a').once.and_return(stub name: 'a')
      pr.should_receive(:read_client_plugins).once.and_return(%w[a b])
      subject.should_not_receive :add_plugin
      subject.send :install_plugin, 'a'
    }

    it("should update the plugins file when plugin not installed yet"){
      p1= stub name: 'a', requirements: nil, auto_install_features: [], run_callback: true
      pr.should_receive(:instance_for).with('a').once.and_return(p1)
      pr.should_receive(:read_client_plugins).at_least(:once).and_return(%w[b])
      subject.should_receive(:add_plugin).once.with(p1)
      subject.should_not_receive(:install_feature)
      subject.send :install_plugin, 'a'
    }

    it("should update the plugins file when nothing installed yet"){
      p1= stub name: 'a', requirements: nil, auto_install_features: [], run_callback: true
      pr.should_receive(:instance_for).with('a').once.and_return(p1)
      pr.should_receive(:read_client_plugins).at_least(:once).and_return(nil)
      subject.should_receive(:add_plugin).once.with(p1)
      subject.should_not_receive(:install_feature)
      subject.send :install_plugin, 'a'
    }

    it("should run the after_installed callback"){
      p1= stub name: 'a', requirements: nil, auto_install_features: []
      pr.should_receive(:instance_for).with('a').once.and_return(p1)
      pr.should_receive(:read_client_plugins).at_least(:once).and_return(nil)
      subject.should_receive(:add_plugin).once.with(p1)
      subject.should_not_receive(:install_feature)
      p1.should_receive(:run_callback).once.with(:after_installed, kind_of(Hash))
      subject.send :install_plugin, 'a'
    }

    it("should validate plugin requirements"){
      p1= mock 'plugin 1'
      p1.stub name: 'a'
      p1.stub(:requirements).and_return({'p2'=>391})
      pr.should_receive(:instance_for).with('a').once.and_return(p1)
      mock_client_state %w[p2], %w[p2:a], {'p2'=>1}
      subject.should_not_receive :add_plugin
      expect{ subject.send :install_plugin, 'a' }.to raise_error /[Rr]equire.+391/
    }

    it("should auto-install specified features"){
      p1= stub name: 'a', requirements: nil, auto_install_features: %w[a b], run_callback: true
      pr.should_receive(:instance_for).with('a').once.and_return(p1)
      pr.should_receive(:read_client_plugins).at_least(:once).and_return(nil)
      subject.should_receive(:add_plugin).once.with(p1)
      subject.stub(:install_feature)
      subject.should_receive(:install_feature).once.with(p1,'a')
      subject.should_receive(:install_feature).once.with(p1,'b')
      subject.send :install_plugin, 'a'
    }
  end

  describe '#template2_au' do
    class AU < Corvid::Generator::Base
      attr_accessor :with_args, :t2_args
      desc 'asd',''
      def asd
        with_auto_update_details(*with_args){
          template2_au *t2_args
        }
      end
      private
      def name; 'bob' end
      def age; 100 end
    end

    before(:each){
      g.with_args= ['p1',g,nil]
      g.t2_args= ['file.tt']
      @expected_au_data= {filename: 'file.tt', generator: {class: AU.to_s}}
      @expected_t_args= ['file.tt' ,'file', {}]
    }

    let(:g){
      g= quiet_generator AU
      g.stub create_file: nil, chmod: nil
      g
    }

    def test
      g.should_receive(:template).once.with *@expected_t_args
      g.should_receive(:add_to_auto_update_file).once.with do |type, plugin_name, data|
        type.should == 'template2'
        plugin_name.should == g.with_args[0]
        data.should == @expected_au_data
      end
      g.asd
    end

    it("generates template and updates auto-update file"){
      test
    }

    it("records the generator class's require path"){
      @expected_au_data[:generator][:require]= g.with_args[2]= 'a/b/c'
      test
    }

    it("accepts the generator class instead of self"){
      g.with_args[1]= AU
      test
    }

    it("saves specified arg values"){
      g.t2_args += [:name, :age]
      @expected_au_data[:args]= {name: 'bob', age: 100}
      test
    }

    it("saves template2 options"){
      g.t2_args<< {perms: 0755}
      g.should_receive(:chmod).once
      @expected_au_data[:options]= {perms: 0755}
      test
    }

    it("all options at once"){
      g.t2_args += [:name, :age, {perms: 0755}]
      g.should_receive(:chmod).once
      @expected_au_data[:args]= {name: 'bob', age: 100}
      @expected_au_data[:options]= {perms: 0755}
      test
    }

    it("fails unless with_auto_update_details() called first"){
      expect{ g.send :template2_au, 'abc' }.to raise_error /with_auto_update_details/
    }
  end
end
