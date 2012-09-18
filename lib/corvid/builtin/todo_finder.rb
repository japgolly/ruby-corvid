module Corvid
  module Builtin
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
          */log/*
          */tmp/*
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
        grep_args<< '--color=always' if STDOUT.tty? # 'auto' doesn't work because output is piped before returning
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

      def run
        r= `#{self.cmd}`
        lines= r.split($/)
        if lines.empty?
          puts "Congratulations. No T\ODOs found."
        else
          puts "Found #{r.split($/).size} T\ODOs."

          # Try to parse and align results
          parsed_ok= true
          lines.map!{|l|
            m= /
                (?<color> (?:\e\[.*?[mK])*){0}
                (?<colon> \g<color>:\g<color>){0}
                ^(?<location> .+? (?:\g<colon>\d+?)? ) \g<colon> \s* (?<content>.+)$
              /x.match l
            m ? [m[:location],m[:content]] : parsed_ok= false
          }
          if parsed_ok
            # Parsing good. Now align content
            width= lines.map{|l| l[0].size}.max
            color_reset= r["\e["] ? "\e[m" : ''
            lines.each{|l|
              printf "%-#{width}s%s %s\n", l[0], color_reset, l[1]
            }
          else
            # Parsing failed - just display what we got
            puts r
          end
        end
      end

      protected

      def q(str)
        return str.map{|s| q s }.join ' ' if str.is_a? Array
        return str if /\A[A-Za-z0-9_.=-]*\z/ === str
        return "'#{str}'" unless str["'"]
        str.inspect
      end
    end
  end
end
