require 'corvid/naming_policy'

module Corvid
  # Allows specification that certain plugins, features and/or resource versions are installed in a client's
  # Corvid-project.
  #
  # @example
  #   rv = Corvid::RequirementValidator.new
  #
  #   # Specify requirements
  #   rv.add 'plugin1', 'plugin2:feature'
  #   rv.add 'plugin3' => 4
  #
  #   # Specify the client project state
  #   rv.set_client_state(...)
  #
  #   # Verify
  #   rv.validate!
  class RequirementValidator
    include NamingPolicy

    def initialize
      @requirements= []
    end

    # Adds new requirements.
    #
    # @example
    #   add 'plugin1', 'plugin2'             # Require plugins
    #   add 'corvid:corvid', 'corvid:plugin' # Require features
    #   add 'corvid' => 3                    # Require resource versions
    #
    # @param [Array<String|Hash>] args Requirements.
    #
    #   A String specifies a requirement for a certain plugin or feature_id to be installed.
    #
    #   A Hash specifies the same (via its keys), and a version requirement in its values. Versions can be specified as:
    #
    #   * A minimum version. eg. `3` meaning at least version 3 is required.
    #   * A version range. eg. `3..5`
    #   * An array of acceptable versions. eg. `[3, 4, 8]`
    # @return [self]
    def add(*args)
      args.flatten.each {|arg|
        arg= {arg => nil} unless arg.is_a? Hash
        arg.each {|k,v|
          req= parse_req_arg(k,v)
          @requirements<< req unless @requirements.include? req
        }
      }
      self
    end

    # Clears all registered requirements.
    #
    # @return [self]
    def clear
      @requirements.clear
      self
    end

    # Provides a list of all registered requirements.
    #
    # *Note:* Results will be in this class's internal format, not the format used in {#add}.
    #
    # @return [Array<Hash<Symbol,Object>>] Requirements in internal format.
    def requirements
      @requirements.dup
    end

    # Specify relevant attributes about the client Corvid project installation. This data is what the requirements will
    # be checking.
    #
    # @param [Array<String>] plugin_names A list of names of plugins installed.
    # @param [nil,Array<String>] feature_ids A list of ids of features installed.
    # @param [nil,Hash<String,Fixnum>] versions Versions of installed resources. Key = plugin name, value = version
    #   number.
    # @return [self]
    def set_client_state(plugin_names, feature_ids, versions)
      raise "Invalid plugin list, Array<String> expected: #{plugin_names.inspect}" unless plugin_names.is_a? Array
      feature_ids ||= []
      raise "Invalid feature id list, Array<String> expected: #{feature_ids.inspect}" unless feature_ids.is_a? Array
      versions ||= {}
      raise "Invalid version map, Hash<String,Fixnum> expected: #{versions.inspect}" unless versions.is_a? Hash
      @plugin_names, @feature_ids, @versions = plugin_names, feature_ids, versions
      self
    end

    # Checks if a single requirement is satisfied.
    #
    # @param [Hash<Symbol,Object>] req The requirement to check. Must be in this class's internal format.
    # @return [nil,String] A string describing why the requirement isn't satisfied, or `nil` if it is satisfied.
    def check(req)
      raise "Client state hasn't been provided yet. Unable to check requirements." unless @plugin_names

      if req[:plugin] and !@plugin_names.include? req[:plugin]
        return "Plugin not installed: #{req[:plugin]}"
      elsif req[:feature_id] and !@feature_ids.include? req[:feature_id]
        return "Feature not installed: #{req[:feature_id]}"
      elsif rv= req[:version]
        v= @versions[p= req[:plugin]] || 0
        case rv
        when Fixnum
          return "Minimum version of #{p} required is #{rv} but #{v} is installed." if v < rv
        when Range
          return "Required version of #{p} is between #{rv.min} and #{rv.max} but #{v} is installed." unless rv === v
        when Array
          return "Required version of #{p} is one of #{rv} but #{v} is installed." unless rv.include? v
        else
          raise "Unknown version requirement specification. Req: #{req.inspect}"
        end
      end

      nil
    end

    # Checks all requirements and provides a list of cases where requirements aren't being met.
    #
    # @return [Array<String>] A list of human-readable messages, or an empty array if all requirements were met.
    def errors
      @requirements.map{|r| check r }.compact.sort
    end

    # Checks all requirements and indicates whether all are being met.
    #
    # @return [Boolean] `true` if all requirements were satisfied, else `false`.
    def validate
      errors.empty?
    end

    # Ensures all requirements are being met.
    #
    # @raise If any requirements are not satisfied.
    # @return [self]
    def validate!
      errors= self.errors
      unless errors.empty?
        detail= errors.size == 1 ? errors[0] : "\n" + errors.map{|e| "  * #{e}" }.join("\n")
        raise "There are unsatisfied requirements: " + detail
      end
      self
    end

    private

    def parse_req_arg(arg,v)
      r= case arg
        when String
          if arg[':']
            # Feature ID
            validate_feature_id! arg
            {plugin: split_feature_id(arg)[0], feature_id: arg}
          else
            # Plugin name
            validate_plugin_name! arg
            {plugin: arg}
          end
        else
          raise "Invalid requirement. Don't know how to parse: #{arg.inspect}"
        end
      r[:version]= v if v
      r
    end
  end
end
