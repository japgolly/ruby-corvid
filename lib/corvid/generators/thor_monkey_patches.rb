require 'thor/util'

module Thor::Util

  # PATCH
  #def self.find_by_namespace(namespace)
  def self.find_by_namespace(namespace, task_name=nil)
    namespace = "default#{namespace}" if namespace.empty? || namespace =~ /^:/
    # PATCH
    #Thor::Base.subclasses.find { |klass| klass.namespace == namespace }
    Thor::Base.subclasses.find { |klass| klass.namespace == namespace and task_name.nil? || klass.tasks.keys.include?(task_name) }
  end

 def self.find_class_and_task_by_namespace(namespace, fallback = true)
    if namespace.include?(?:) # look for a namespaced task
      pieces = namespace.split(":")
      task   = pieces.pop

      # PATCH
      #klass  = Thor::Util.find_by_namespace(pieces.join(":"))
      actual_namespace = pieces.join(":")
      klass = Thor::Util.find_by_namespace(actual_namespace, task)
      klass ||= Thor::Util.find_by_namespace(actual_namespace)
      # END PATCH

    end
    unless klass # look for a Thor::Group with the right name
      klass, task = Thor::Util.find_by_namespace(namespace), nil
    end
    if !klass && fallback # try a task in the default namespace
      task = namespace
      klass = Thor::Util.find_by_namespace('')
    end
    return klass, task
  end

end
