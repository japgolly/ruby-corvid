require 'corvid/generators/base'

class Corvid::Generator::Update < Corvid::Generator::Base

  desc 'installed', 'Updates all installed Corvid features.'
  def installed

    # Read installation details
    ver= read_deployed_corvid_version!
    features= get_installed_features!

    # Corvid installation confirmed - now check if already up-to-date
    if rpm.latest? ver
      say "Already up-to-date."
    else
      # Perform upgrade
      from= ver
      to= rpm.latest_version
      say "Upgrading from v#{from} to v#{to}..."
      upgrade! from, to, features
    end
  end

  protected

  def upgrade!(from, to, features)

    # Expand versions m->n
    rpm.with_resource_versions from, to do

      # Collect a list of deployable files and installers
      deployable_files= []
      installers= {}
      from.upto(to) {|v|
        installers[v]= {}
        features.each {|f|
          if code= feature_installer_code(rpm.ver_dir(v), f)
            deployable_files.concat extract_deployable_files(code, f, v)
            installers[v][f]= dynamic_installer(code, f, v)
          end
        }
        deployable_files.sort!.uniq!
      }

      # Patch & migrate installed files
      rpm.migrate from, to, '.', deployable_files unless deployable_files.empty?

      # Perform migration steps
      (from + 1).upto(to) do |ver|
        next unless grp= installers[ver]
        with_resources rpm.ver_dir(ver) do
          grp.each do |feature,installer|

            # Call update() in the installer
            installer.update ver if installer.respond_to?(:update)
          end
        end
      end

      # Update version.yml
      write_version to
    end
  end

  # @param [String] installer_script The contents of the `corvid-features/{feature}.rb` script.
  def extract_deployable_files(installer_code, feature, ver)
    x= DeployableFileExtractor.new
    add_dynamic_code! x, installer_code, feature, ver
    x.install
    x.files
  end

  private

  # @!visibility private
  class DeployableFileExtractor
    KEYWORDS= %w[
      copy_file
      copy_executable
      copy_file_unless_exists
    ].map(&:to_sym).freeze

    attr_reader :files
    def initialize; @files= [] end
    def method_missing(method,*args)
      if KEYWORDS.include? method
        raise "One argument expected for #{method} but received #{args.inspect}" unless args.size == 1
        files<< args[0]
      end
    end
  end

end
