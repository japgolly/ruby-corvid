require 'corvid/generators/base'

class Corvid::Generator::Update < ::Corvid::Generator::Base

  desc 'project', 'Updates all Corvid resources and features in the current project.'
  def project

    # Read client details
    vers= read_client_versions!
    features= read_client_features!

    # TODO update only updates corvid
    plugin_name= 'corvid'
    ver= vers[plugin_name]

    # Corvid installation confirmed - now check if already up-to-date
    if rpm.latest? ver
      say "Upgrading #{plugin_name}: Already up-to-date."
    else
      # Perform upgrade
      from= ver
      to= rpm.latest_version
      say "Upgrading #{plugin_name} from v#{from} to v#{to}..."
      upgrade! plugin_name, from, to, features
    end
  end

  protected

  # @param [String] plugin_name The name of the plugin whose resources are being updated.
  # @param [Fixnum] from The version already installed.
  # @param [Fixnum] to The target version to upgrade to.
  # @param [Array<String>] features The features to upgrade.
  # @return [void]
  def upgrade!(plugin_name, from, to, features)
    #TODO update or upgrade - make up mind!

    # Expand versions m->n
    rpm.with_resource_versions from, to do

      # Collect a list of deployable files and installers
      deployable_files= []
      installers= {}
      from.upto(to) {|v|
        installers[v]= {}
        features.each {|feature_id|
          # TODO update doesn't handle multiple plugins
          feature_name= split_feature_id(feature_id)[1]
          if code= feature_installer_code(rpm.ver_dir(v), feature_name)
            deployable_files.concat extract_deployable_files(code, feature_id, v)
            installer= dynamic_installer(code, feature_id, v)
            installers[v][feature_name]= installer if installer.respond_to?(:update)
          end
        }
        deployable_files.sort!.uniq!
      }

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
            installer.update ver

          end
        end
      end

      # Update version file
      add_version plugin_name, to
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

    def method_missing(method,*args)
      # Ignore
    end
  end

end
