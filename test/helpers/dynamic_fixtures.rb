require 'fileutils'
require 'tmpdir'

module DynamicFixtures

  def copy_dynamic_fixture(name, target_dir='.')
    FileUtils.cp_r "#{dynamic_fixture_dir name}/.", target_dir
  end

  def dynamic_fixture_dir(name)
    df= get_dynamic_fixture_data(name)

    if !df
      raise "Undefined dynamic fixture: #{name}"
    elsif df[:block]
      dir= "#{dynamic_fixture_root}/#{name}"
      Dir.mkdir dir
      if subdir= df[:dir_name]
        dir+= "/#{subdir}"
        Dir.mkdir dir
      end
      Dir.chdir(dir){ instance_eval &df[:block] }
      df.delete :block
      df[:dir]= dir
    end

    df[:dir].dup
  end

  def inside_dynamic_fixture(fixture_name, cd_into=nil, &block)
    Dir.mktmpdir {|dir|
      Dir.chdir dir do
        copy_dynamic_fixture fixture_name
        cd_into ||= get_dynamic_fixture_data(fixture_name)[:cd_into]
        if cd_into
          orig_block= block
          block= ->{ Dir.chdir(cd_into){ orig_block.() }}
        end
        block.()
      end
    }
  end

  private

  def get_dynamic_fixture_data(name)
    name= DynamicFixtures.normalise_dynfix_name(name)
    $dynamic_fixtures[name]
  end

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

    def def_fixture(name, options={}, &block)
      raise "Block not provided." unless block
      name= DynamicFixtures.normalise_dynfix_name(name)
      STDERR.warn "Dyanmic fixture being redefined: #{name}." if $dynamic_fixtures[name]

      invalid_options= options.keys - VALID_DEF_FIXTURE_OPTIONS
      raise "Invalid options: #{invalid_options}" unless invalid_options.empty?

      $dynamic_fixtures[name]= options.merge(block: block)
      self
    end

    VALID_DEF_FIXTURE_OPTIONS= [:cd_into, :dir_name].freeze

    def run_each_in_dynamic_fixture(fixture_name, cd_into=nil)
      raise "Block not supported." if block_given?
      class_eval <<-EOB
        around :each do |ex|
          inside_dynamic_fixture(#{fixture_name.inspect}, #{cd_into.inspect}){ ex.run }
        end
      EOB
    end

  end

  extend ClassMethods
end
