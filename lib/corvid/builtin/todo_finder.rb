module Corvid
  class TodoFinder
    attr_accessor :dir
    attr_accessor :find_bin, :find_conds, :ignore_paths, :ignore_names
    attr_accessor :find_result_pipes
    attr_accessor :xargs_bin
    attr_accessor :grep_bin, :grep_args, :grep_for

    def initialize
      self.dir= '.'
      self.find_bin= 'find'
      self.find_conds= %w[-type f]
      self.ignore_paths= %w[
        */.git/*
        */.svn/*
        */.idea/*
        */.settings/*
        */.metadata/*
        */target/*
      ]
      self.ignore_names= %w[
        .*.sw[p-z]
        ~*
        *.bak
        *.log
        *.tmp
        *.out
        *.err
        *.patch
        *.tt
      ]
      self.find_result_pipes= ['sort']
      self.xargs_bin= 'xargs'
      self.grep_bin= 'grep'
      self.grep_args= %w[-n]
      grep_args<< '--color=always' if STDOUT.tty? # auto doesn't work, probably cos I'm capturing output via backticks
      self.grep_for= 'T''ODO.*$'
    end

    def ignore_cond
      conds= []
      conds.concat [ignore_paths].flatten.compact.map{|p| "-path #{q p}" }
      conds.concat [ignore_names].flatten.compact.map{|n| "-name #{q n}" }
      conds.empty? ? '' : %[! '(' #{conds.join ' -o '} ')']
    end

    def find_cmd
      "#{q find_bin} #{q dir} #{q find_conds} #{ignore_cond}"
    end

    def cmd
      cmds= [find_cmd] + find_result_pipes
      cmds<< "#{q xargs_bin} #{q grep_bin} #{q grep_args} #{q grep_for}"
      cmds.join ' | '
    end

    def q(str)
      return str.map{|s| q s }.join ' ' if str.is_a? Array
      return str if /\A[A-Za-z0-9_.=-]*\z/ === str
      return "'#{str}'" unless str["'"]
      str.inspect
    end
  end
end
