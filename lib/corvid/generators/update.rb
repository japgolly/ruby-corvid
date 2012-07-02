require 'corvid/generators/base'

class Corvid::Generator::Update < Corvid::Generator::Base

  desc 'deps', 'Update dependencies. (Recreates Gemfile.corvid)'
  method_options :'dry-run' => false
  def self.add_update_deps_options(t)
    t.method_options use_corvid_gem: true
    t.method_options :'bundle-install' => true
  end
  add_update_deps_options self
  def deps
    d= DepBuilder.new(options)
    d.instance_eval File.read("#{self.class.source_root}/Gemfile.corvid")
    content= d.to_s
    if options[:'dry-run']
      puts content
    else
      create_file 'Gemfile.corvid', content
      if options[:'bundle-install'] and !$corvid_bundle_install_at_exit_installed
        $corvid_bundle_install_at_exit_installed= true
        at_exit{ run "bundle install" }
      end
    end
  end

  private

  class DepBuilder
    attr_reader :options

    def initialize(options)
      @options= options
      @header= []
      @libs= {}
      @footer= []
    end

    def header(line)
      @header<< line
    end

    def footer(line)
      @footer<< line
    end

    def group(*names)
      @groups= names
      yield self
      nil
    ensure
      @groups= nil
    end

    def gem(lib, *args)
      options= args.last.kind_of?(Hash) ? args.pop : {}
      if @groups
        options[:group]= [options[:group],@groups].flatten.compact.uniq.sort_by(&:to_s)
        options[:group]= options[:group].first if options[:group].size == 1
      end

      group= options.delete(:group)
      bucket= (@libs[group] ||= [])

      a= ([lib] + args).map(&:inspect)
      a.concat options.to_a.map{|k,v| "#{k}: #{v.inspect}" }
      bucket<< "gem #{a.join ', '}"
      true
    end

    def to_s
      lines= []
      lines.concat @header + [''] unless @header.empty?
      @libs[nil].sort.each{|l| lines<< l } if @libs[nil]
      @libs.keys.compact.sort_by(&:to_s).map do |g|
        lines<< "group #{g.inspect} do"
        @libs[g].sort.each{|l| lines<< "  #{l}"}
        lines<< "end"
        end.to_a
      lines.concat [''] + @footer unless @footer.empty?
      lines.join "\n"
    end
  end
end
