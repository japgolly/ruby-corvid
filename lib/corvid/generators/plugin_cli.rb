require 'corvid/generators/base'
require 'corvid/generators/update'
require 'golly-utils/attr_declarative'

# Generator to be used specifically by {Corvid::PluginCli}.
#
# The tasks that appear here will be available (without a namespace) to the plugin CLI that is generated when one
# generates a Corvid plugin.
#
# Before use, {#plugin} must be declared.
class Corvid::Generator::PluginCli < ::Corvid::Generator::Base

  # @!attribute [rw] plugin
  #   @return [Plugin]
  no_tasks{
    attr_declarative :plugin, required: true
  }

  desc 'install', 'Install this plugin.'
  def install
    install_plugin plugin
  end

  desc 'update', 'Update this plugin.'
  def update
    ::Corvid::Generator::Update.new.update plugin.name
  end
end
