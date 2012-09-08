require 'corvid/generators/base'

class Corvid::Generator::Update < ::Corvid::Generator::Base

  desc 'all', 'Update all features and plugins.'
  def all
    update nil
  end

  def self.add_tasks_for_installed_plugins!
    plugin_names= ::Corvid::PluginRegistry.instances_for_installed.keys
    class_eval plugin_names.map{|name|
      %|
        desc '#{name}', 'Update the #{name} plugin and its installed features.'
        def #{name}; update '#{name}'; end
      |}
      .join(";")
  end

  # Stupid Thor. Not using no_tasks{} cos then yard won't see this method.
  @no_tasks= true

  def update(plugin_filter)

    # Read client details
    vers= read_client_versions
    feature_ids= feature_registry.read_client_features

    # Group features by plugin
    features_by_plugin= {}
    feature_ids.each {|id|
      p,f = split_feature_id(id)
      (features_by_plugin[p] ||= [])<< f if vers[p]
    } if vers && feature_ids

    # Apply plugin filter
    if plugin_filter
      features_by_plugin.delete_if {|plugin_name,_| not plugin_filter === plugin_name }
    end

    # Check if anything left to update
    if features_by_plugin.empty?
      plugin_msg= "for the '#{plugin_filter}' plugin " if plugin_filter.is_a?(String)
      say "There is nothing installed #{plugin_msg}that can be updated."
      return
    end

    # Update each plugin
    features_by_plugin.each do |plugin_name, features|
      next unless plugin_filter.nil? or plugin_filter === plugin_name
      plugin= plugin_registry[plugin_name]
      ver= vers[plugin_name]

      # Check if already up-to-date
      if rpm_for(plugin).latest? ver
        say "Upgrading #{plugin.name}: Already up-to-date."
      else
        # Perform upgrade
        from= ver
        to= rpm_for(plugin).latest_version
        say "Upgrading #{plugin.name} from v#{from} to v#{to}..."
        upgrade! plugin, from, to, features
      end

      # Done with this plugin
      say ""
    end
  end

  protected

  # @param [Plugin] plugin The plugin whose resources are being updated.
  # @param [Fixnum] from The version already installed.
  # @param [Fixnum] to The target version to upgrade to.
  # @param [Array<String>] feature_names The names of features to upgrade.
  # @return [void]
  def upgrade!(plugin, from, to, feature_names)
    #TODO update or upgrade - make up mind!
    rpm= rpm_for(plugin)

    # Expand versions m->n
    rpm.with_resource_versions from, to do

      # Collect a list of deployable files and installers
      deployable_files= []
      installers= {}
      from.upto(to) {|v|
        installers[v]= {}
        feature_names.each {|feature_name|
          if code= feature_installer_code(rpm.ver_dir(v), feature_name)
            feature_id= feature_id_for(plugin.name, feature_name)
            deployable_files.concat extract_deployable_files(code, feature_id, v)
            installer= dynamic_installer(code, feature_id, v)
            installers[v][feature_name]= installer if installer.respond_to?(:update)
          end
        }
        deployable_files.sort!.uniq!
      }

      # Validate requirements
      if installers[to]
        rv= new_requirement_validator
        rv.add installers[to].values.map{|fi| fi.respond_to?(:requirements) ? fi.requirements : nil }
        rv.validate!
      end

      # Patch & migrate deployable files
      unless deployable_files.empty?
        rpm.allow_interactive_patching do
          say_status 'patch', "Patching installed files...", :cyan
          if rpm.migrate from, to, '.', deployable_files
            say_status 'patch', 'Applied but with merge conflicts.', :red
          else
            say_status 'patch', 'Applied cleanly.', :green
          end
        end
      end

      # Perform migration steps
      (from + 1).upto(to) do |ver|
        next unless grp= installers[ver]
        with_resources rpm.ver_dir(ver) do
          grp.each do |feature,installer|

            # So that it doesn't overwrite a file being patched, disable commands that patching is taking care of
            installer.instance_eval "def copy_file(*) end"

            # Call update() in the installer
            with_action_context(installer) {
              installer.update ver
            }

          end
        end
      end

      # Update version file
      add_version plugin.name, to
    end
  end

  # @param [String] installer_code The contents of the `corvid-features/{feature}.rb` script.
  # @return [Array<String>]
  def extract_deployable_files(installer_code, feature, ver)
    x= DeployableFileExtractor.new
    add_dynamic_code! x, installer_code, feature, ver
    x.install
    x.files
  end

  private

  # @!visibility private
  class DeployableFileExtractor
    include ::Corvid::Generator::ActionExtentions

    attr_reader :files
    def initialize; @files= [] end

    def copy_file(file, rename=nil, options={})
      raise "copy_file(): Renaming unsupported." if rename and rename != file
      raise "copy_file(): Options not supported." if options and !options.empty?
      files<< file
    end
    def copy_file_unless_exists(src, tgt=nil, options={})
      copy_file src, tgt, options
    end
    def template(*args)
      # Ignore
    end

    def method_missing(method,*args)
      # Ignore
    end
  end

  # Re-enable Thor's support for assuming all public methods are tasks
  no_tasks {}
end
