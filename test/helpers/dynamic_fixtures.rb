require 'fileutils'
require 'tmpdir'

module DynamicFixtures

  def copy_dynamic_fixture(name, target_dir='.')
    FileUtils.cp_r "#{dynamic_fixture_dir name}/.", target_dir
  end

  def dynamic_fixture_dir(name)
    name= DynamicFixtures.normalise_dynfix_name(name)
    case value= $dynamic_fixtures[name]
    when nil
      raise "Undefined dynamic fixture: #{name}"
    when String
      return value
    when Proc
      dir= "#{dynamic_fixture_root}/#{name}"
      Dir.mkdir dir
      Dir.chdir(dir){ instance_eval &value }
      return $dynamic_fixtures[name]= dir
    else
      raise "Unexpected value for #{name}: #{value.inspect}"
    end
  end

  def inside_dynamic_fixture(fixture_name)
    Dir.mktmpdir {|dir|
      Dir.chdir dir do
        copy_dynamic_fixture fixture_name
        yield
      end
    }
  end

  private

  def dynamic_fixture_root
    $dynamic_fixture_root ||= (
      at_exit{
        FileUtils.remove_entry_secure $dynamic_fixture_root if $dynamic_fixture_root
        $dynamic_fixtures= $dynamic_fixture_root= nil
      }
      Dir.mktmpdir
    )
  end

  def self.normalise_dynfix_name(name)
    name.to_sym
  end

  $dynamic_fixtures= {}
  $dynamic_fixture_root= nil

  #---------------------------------------------------------------------------------------------------------------------

  def self.included(base)
    base.extend ClassMethods
  end

  module ClassMethods

    def def_fixture(name, &block)
      raise "Block not provided." unless block
      name= DynamicFixtures.normalise_dynfix_name(name)
      STDERR.warn "Dyanmic fixture being redefined: #{name}." if $dynamic_fixtures[name]
      $dynamic_fixtures[name]= block
      self
    end

    def run_each_in_dynamic_fixture(fixture_name)
      class_eval <<-EOB
        around :each do |ex|
          inside_dynamic_fixture(#{fixture_name.inspect}){ ex.run }
        end
      EOB
    end

  end

  extend ClassMethods
end
