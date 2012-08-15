require 'corvid/generators/base'

class Corvid::Generator::NewFeature < ::Corvid::Generator::Base
  namespace 'new'

  argument :feature_name, type: :string

  desc 'feature', 'Generates a new plugin feature.'
  def feature
    with_latest_resources(builtin_plugin) do
      template2 'lib/corvid/%name%_feature.rb.tt', :name
      #template2 'test/spec/%name%_feature_spec.rb.tt', :name
      template2 'resources/latest/corvid-features/%name%.rb.tt', :name

      # Add to feature manifest
      if plugin_file= find_client_plugin
        insert_into_file plugin_file, "    '#{name}' => ['#{require_path}','::#{class_name}'],\n",
          after: /^\s*feature_manifest\s*\(.*?\n/
      end
    end
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
  def name; feature_name.underscore.gsub(/^.*[\\\/]+|\.rb$/,'') end
  def class_name; name.camelize + 'Feature' end
  def require_path; "corvid/#{name}_feature" end
  def since_ver
    @since_ver ||= (
      Corvid::ResPatchManager.new("resources").latest_version + 1
    )
  end
end
