require 'corvid/generators/base'

class Corvid::Generator::NewPlugin < ::Corvid::Generator::Base
  namespace 'new'

  argument :plugin_name, type: :string

  desc 'plugin', 'Creates a new Corvid plugin.'
  def plugin
    validate_requirements! 'corvid:plugin'
    with_latest_resources(builtin_plugin) {
      template2 'lib/corvid/%name%_plugin.rb.tt', :name
      template2 'test/spec/%name%_plugin_spec.rb.tt', :name
      template2 'bin/%plugin_name%.tt', plugin_name: name, perms: 0755
    }
  end

  # Template vars
  private
  def name; plugin_name.underscore.gsub(/^.*[\\\/]+|\.rb$/,'') end
  def class_name; name.camelize + 'Plugin' end
  def require_path; "corvid/#{name}_plugin" end
end
