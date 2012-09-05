module Corvid
  # Used to parse `Gemfile` content and provide list of declared gems.
  #
  # @see Generator::ActionExtentions#add_dependencies_to_gemfile
  class GemfileEvaluator

    # @return [Array<String>] List of declared gems.
    attr_reader :gems

    def initialize
      @gems= {}
    end

    # Evaluates a string containing `Gemfile` content.
    #
    # @param [String] content `Gemfile` DSL.
    # @return [self]
    def eval_string(content)
      instance_eval content
      self
    end

    # @!visibility private
    def group(group_name, *args)
      return unless block_given?
      prev_group_name= @group_name
      begin
        @group_name= group_name
        yield
      ensure
        @group_name= prev_group_name
      end
      nil
    end

    # @!visibility private
    def gem(gem_name, *args)
      if @group_name
        args= args.dup
        args<< {} unless args.last.is_a?(Hash)
        args.last[:group] ||= @group_name
      end
      @gems[gem_name]= args
      nil
    end

    # @!visibility private
    def method_missing(method, *args, &block)
      instance_eval &block if block
      nil
    end

  end
end
