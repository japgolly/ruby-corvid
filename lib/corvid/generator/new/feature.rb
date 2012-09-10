require 'corvid/generator/base'

class Corvid::Generator::NewFeature < ::Corvid::Generator::Base
  namespace 'new'

  argument :name, type: :string

  desc 'feature', 'Generates a new plugin feature.'
  def feature
    validate_requirements! 'corvid:plugin'
    with_latest_resources(builtin_plugin) {
      template2 'lib/%project_name%/%feature_name%_feature.rb.tt'
      template2 'resources/latest/corvid-features/%feature_name%.rb.tt'

      # Add to feature manifest
      if plugin_file= find_client_plugin
        insert_into_file plugin_file, "      '#{feature_name}' => ['#{require_path}','::#{full_class_name}'],\n",
          after: /^\s*feature_manifest\s*\(.*?\n/
      end
    }
  end

  protected

  # Tries to find a single client-side Corvid plugin.
  #
  # @return [String|nil] The plugin filename if found.
  def find_client_plugin
    plugin_files= Dir['lib/**/*_plugin.rb'].select{|f| File.read(f)['Corvid::Plugin'] }
    plugin_file= plugin_files.first
  end

  # Template vars
  private
  def feature_name; name.underscore.gsub(/^.*[\\\/]+|\.rb$/,'').sub(/_feature$/,'') end
  def require_path; "#{project_name}/#{feature_name}_feature" end
  def class_name; feature_name.camelize + 'Feature' end
  def full_class_name; "#{project_module}::#{class_name}" end
  def since_ver
    @since_ver ||= (
      Corvid::ResPatchManager.new("resources").latest_version + 1
    )
  end
end
