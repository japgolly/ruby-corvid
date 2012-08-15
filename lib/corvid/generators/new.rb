require 'corvid/generators/base'

class Corvid::Generator::New < ::Corvid::Generator::Base

  argument :plugin_name, type: :string
  desc 'plugin', 'Creates a new Corvid plugin.'
  def plugin
    with_latest_resources(builtin_plugin) do
      template2 'lib/corvid/%name%_plugin.rb.tt', :name
      template2 'test/spec/%name%_plugin_spec.rb.tt', :name
      template2 'bin/%plugin_name%.tt', plugin_name: name, perms: 0755
    end
  end

  # Template vars
  private
  def name; plugin_name.underscore.gsub(/^.*[\\\/]+|\.rb$/,'') end
  def class_name; name.camelize + 'Plugin' end
  def require_path; "corvid/#{name}_plugin" end

  #---------------------------------------------------------------------------------------------------------------------

  class Plugin < ::Corvid::Generator::Base
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

  #---------------------------------------------------------------------------------------------------------------------

  class Test < ::Corvid::Generator::Base
    argument :name, type: :string

    desc 'unit', 'Generates a new unit test.'
    def unit
      with_latest_resources(builtin_plugin) do
        template2 'test/unit/%src%_test.rb.tt', :src
      end
    end

    desc 'spec', 'Generates a new specification.'
    def spec
      with_latest_resources(builtin_plugin) do
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
