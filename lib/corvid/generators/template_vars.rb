module Corvid
  module Generator

    # Provides methods that may be useful to templates.
    module TemplateVars

    # TODO
    def project_name
      # lib/???
      # gemspec
      # pwd
      File.basename Dir.pwd
    end

    def project_module; project_name.gsub('-','_').camelize end
    def author_name; get_git_config 'user.name' end
    def author_email; get_git_config 'user.email' end

    def get_git_config(name)
      v= `git config --get #{name}`.chomp rescue nil
      $?.success? && !v.empty? ? v : nil
    end

    end
  end
end
