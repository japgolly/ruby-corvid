require 'corvid/generator/base'

# Task that updates resouces deployed in clients' Corvid projects.
class Corvid::Generator::Update < ::Corvid::Generator::Base

  # List of actions (i.e. methods defined in Thor actions or ActionExtensions) that are updated automatically simply
  # by being registered in a feature installers `install{}` block. These actions do not need to be repeated in an
  # `update{}` block.
  AUTO_UPDATE_ACTIONS= [
    :copy_file,
    :create_file,
    :template,
    :template2,
  ].freeze

  desc 'all', 'Update all features and plugins.'
  def all
    update nil
  end

  # Dynamically creates an update task for each registered plugin installed in a client's Corvid project.
  #
  # Uses {Corvid::PluginRegistry#instances_for_installed} to determine which plugins to create tasks for.
  #
  # @return [void]
  def self.create_update_tasks_for_installed_plugins!
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

  # Updates resouces deployed in client's Corvid project.
  #
  # @param [nil|Regexp|String] plugin_filter A filter applied to plugin name's (via `===`) to select a subset of
  #   installed plugins, and only update those. If `nil` then all installed plugins will be updated.
  # @return [void]
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
        # Perform update
        from= ver
        to= rpm_for(plugin).latest_version
        say "Upgrading #{plugin.name} from v#{from} to v#{to}..."
        update! plugin, from, to, features
      end

      # Done with this plugin
      say ""
    end
  end

  protected

  # Updates a single plugin.
  #
  # @param [Plugin] plugin The plugin whose resources are being updated.
  # @param [Fixnum] from The version already installed.
  # @param [Fixnum] to The target version to update to.
  # @param [Array<String>] feature_names The names of features to update.
  # @return [void]
  def update!(plugin, from, to, feature_names)
    rpm= rpm_for(plugin)

    # Expand versions m->n
    rpm.with_resource_versions from, to do

      # Collect installer data
      installers= {}
      from.upto(to) {|v|
        installers[v]= {}
        feature_names.each {|feature_name|
          if code= feature_installer_code(rpm.ver_dir(v), feature_name)
            fd= installers[v][feature_name]= {}
            fd[:code]= code
            fd[:feature_id]= feature_id_for(plugin.name, feature_name)
            fd[:installer]= dynamic_installer fd[:code], fd[:feature_id], v
          end
        }
      }

      # Validate requirements
      if installers[to]
        rv= new_requirement_validator
        rv.add installers[to]
                 .values
                 .map{|fd| fd[:installer] }
                 .map{|fi| fi.respond_to?(:requirements) ? fi.requirements : nil }
        rv.validate!
      end

      # Auto-update eligible files
      update_deployable_files! rpm, installers, from, to
      update_templates! rpm, installers, from, to
#      update_loose_templates! rpm, from, to

      # Perform migration steps
      (from + 1).upto(to) do |ver|
        next unless grp= installers[ver]
        with_resources rpm.ver_dir(ver) do
          grp.each do |feature,fd|
            installer= fd[:installer]
            if installer.respond_to?(:update)

              # Disable actions that have been auto-updated so that already-patched files aren't overwritten
              installer.instance_eval AUTO_UPDATE_ACTIONS.map{|m| "def #{m}(*) end" }.join ';'

              # Call update() in the installer
              with_action_context(installer) {
                installer.update ver
              }

            end
          end
        end
      end

      # Update version file
      add_version plugin.name, to
    end
  end

  #---------------------------------------------------------------------------------------------------------------------
  private

  # Auto-updates files deployed by `copy_file`.
  #
  # @param [Fixnum] from Current version of resources installed.
  # @param [Fixnum] to Version of resources to update to.
  # @return [void]
  def update_deployable_files!(rpm, installers, from, to)

    # Build a list of files
    files= []
    installers.each do |v,features|
      features.each do |name,fd|
        r= extract_deployable_files fd[:code], fd[:feature_id], v
        files.concat r
      end
    end
    files.sort!.uniq!

    # Patch & migrate files
    unless files.empty?
      patch rpm, "Patching installed files..." do
        rpm.migrate_changes_between_versions from, to, '.', files
      end
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

  class DeployableFileExtractor
    include ::Corvid::Generator::ActionExtensions

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

  #---------------------------------------------------------------------------------------------------------------------

  # Auto-updates files deployed by `create_file`, `template`, {ActionExtensions#template2}.
  #
  # @param [Fixnum] from Current version of resources installed.
  # @param [Fixnum] to Version of resources to update to.
  # @return [void]
  def update_templates!(rpm, installers, from, to)
    Dir.mktmpdir {|tmpdir|
      Dir.mkdir from_dir= "#{tmpdir}/a"
      Dir.mkdir to_dir= "#{tmpdir}/b"

      # Build a list of files
      files= []
      [ [from,from_dir] , [to,to_dir] ].each do |ver,dir|
        next unless grp= installers[ver]
        with_resources rpm.ver_dir(ver) do
          grp.each do |feature,fd|

            # Run installer and create files with dynamic content
            Dir.chdir(dir) {
              r= process_templates fd[:code], fd[:feature_id], ver
              files.concat r
            }

          end
        end
      end

      # Patch & migrate files
      unless files.empty?
        patch rpm, "Patching generated templates..." do
          rpm.migrate_changes_between_dirs from_dir, to_dir, '.', files
        end
      end
    }
  end

  def process_templates(installer_code, feature, ver)
    x= TemplateProcessor.new self
    add_dynamic_code! x, installer_code, feature, ver
    x.install
    x.files
  end

  class TemplateProcessor
    include ::Corvid::Generator::ActionExtensions
    include ::Corvid::Generator::TemplateVars

    attr_reader :files
    def initialize(base)
      @base= base
      @files= []
    end

    METHODS_TO_DELEGATE= [
      :find_in_source_paths,
    ].freeze

    class_eval [:template, :template2].map {|m| <<-EOB
        alias :xxx__#{m} :#{m}
        def #{m}(*args, &block)
          old= @in_template
          @in_template= true
          xxx__#{m} *args, &block
        ensure
          @in_template= old
        end
      EOB
    }.join "\n"

    def create_file(file, *args, &block)
      content= args.first || block.()
      files<< file
      FileUtils.mkdir_p File.dirname(file)
      File.write file, content
    end

    def method_missing(method,*args,&block)
      if METHODS_TO_DELEGATE.include? method
        @base.send method,*args,&block
      elsif @in_template
        # A missing method inside template() means a missing variable method.
        super method,*args,&block
      else
        # Ignore other actions
      end
    end
  end

  #---------------------------------------------------------------------------------------------------------------------

  def patch(rpm, msg, &block)
    rpm.allow_interactive_patching do
      say_status 'patch', msg, :cyan

      conflicts= block.()

      if conflicts
        say_status 'patch', 'Applied but with merge conflicts.', :red
      else
        say_status 'patch', 'Applied cleanly.', :green
      end
    end
  end

  # @param [Array<Hash>]
  def update_loose_templates!(rpm, from, to, template_manifest)
    return unless template_manifest && !template_manifest.empty?

    # TODO should template var methods in FIs be available??
    # TODO rename update_loose_templates, create_template_var_delegator, patch() msg

    @destination_stack.push '.'
    begin
      Dir.mktmpdir {|tmpdir|
        Dir.mkdir from_dir= "#{tmpdir}/a"
        Dir.mkdir to_dir= "#{tmpdir}/b"

        # Build a list of files
        files= []
        [ [from,from_dir] , [to,to_dir] ].each do |ver,dir|
          with_resources rpm.ver_dir(ver) do
              Dir.chdir(dir) {

                template_manifest.each do |td|
                  filename= td[:filename]
                  options= td[:options] || {}
                  d= create_template_var_delegator(td)
                  with_action_context(d){
                    files<< template2(filename, options)
                  }
                end

              }
          end
        end

        # Patch & migrate files
        unless files.empty?
          patch rpm, "TODO Patching other generated templates..." do
            rpm.migrate_changes_between_dirs from_dir, to_dir, '.', files
          end
        end
      }

    ensure
      @destination_stack.pop
    end
  end

  def create_template_var_delegator(td)

    generator= nil
    if gd= td[:generator]
      require gd[:require] if gd[:require]
      raise "Class name not provided for generator.\n#{td.inspect}" unless gd[:class]
      klass= eval gd[:class]
      generator= klass.new
    end

    # TODO cache delegator within this method, created in `from`, reused in `to`
    args_provider= nil
    args= td[:args]
    if args && !args.empty?

      if generator
        args.each{|k,v| generator.instance_variable_set :"@_corvid_#{k}", v }
        generator.instance_eval args.keys.map{|k| "def #{k}; @_corvid_#{k} end" }.join ';'
      else
        klass= Struct.new(*args.keys)
        generator= klass[*args.values]
      end
    end

#    delegates= [args_provider,generator].compact
#    d= GollyUtils::Delegator.new *delegates, allow_protected: true
    generator
  end

  # Re-enable Thor's support for assuming all public methods are tasks
  no_tasks {}
end
