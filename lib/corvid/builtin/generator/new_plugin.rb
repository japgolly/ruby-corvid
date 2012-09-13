require_relative 'base'

class Corvid::Builtin::Generator::NewPlugin < ::Corvid::Generator::Base
  namespace 'new'

  argument :name, type: :string

  desc 'plugin', 'Creates a new Corvid plugin.'
  def plugin
    validate_requirements! 'corvid:plugin'
    with_latest_resources(builtin_plugin) {
      with_auto_update_details(require: __FILE__) {
        template2_au 'lib/%project_name%/%plugin_name%_plugin.rb.tt'
        template2_au 'test/spec/%plugin_name%_plugin_spec.rb.tt'
        template2_au 'bin/%plugin_name%.tt', perms: 0755
        add_executable_to_gemspec "#{project_name}.gemspec", plugin_name
      }
    }
  end

  # Template vars
  private
  def plugin_name; name.underscore.gsub(/^.*[\\\/]+|\.rb$/,'').sub(/_plugin$/,'') end
  def require_path; "#{project_name}/#{plugin_name}_plugin" end
  def class_name; plugin_name.camelize + 'Plugin' end
  def full_class_name; "#{project_module}::#{class_name}" end
end
