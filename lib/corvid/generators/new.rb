require 'corvid/generators/base'

class Corvid::Generator::New < Corvid::Generator::Base

  argument :plugin_name, type: :string
  desc 'plugin', 'Creates a new Corvid plugin.'
  def plugin
    with_latest_resources do
      vars= {
        name: name.underscore.gsub(/^.*[\\\/]+|\.rb$/,''),
      }
      vars[:class_name]= vars[:name].camelize + 'Plugin'
      template2 'lib/corvid/%name%_plugin.rb.tt', vars
      template2 'test/spec/%name%_plugin_spec.rb.tt', vars
    end
  end

  # Template vars
  private
  def name; plugin_name.underscore.gsub(/^.*[\\\/]+|\.rb$/,'') end
  def class_name; name.camelize + 'Plugin' end
  def require_path; "lib/corvid/#{name}_plugin" end

  #---------------------------------------------------------------------------------------------------------------------

  class Test < Corvid::Generator::Base
    argument :name, type: :string

    desc 'unit', 'Generates a new unit test.'
    def unit
      with_latest_resources do
        template2 'test/unit/%src%_test.rb.tt', :src
      end
    end

    desc 'spec', 'Generates a new specification.'
    def spec
      with_latest_resources do
        template2 'test/spec/%src%_spec.rb.tt', :src
      end
    end

    # Template vars
    private
    def src; name.underscore.gsub /^[\\\/]+|\.rb$/, '' end
    def bootstrap_dir; '../'*src.split(/[\\\/]+/).size + 'bootstrap' end
    def testcase_name; src.split(/[\\\/]+/).last.camelcase end
    def subject; src.camelcase end
  end

end
