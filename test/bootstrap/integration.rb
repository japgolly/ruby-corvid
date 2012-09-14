require_relative 'all'

module GollyUtils::Testing::DynamicFixtures
  def after_dynamic_fixture_creation(name, creation_time_in_sec)
    printf "\e[0;36m  Created dynamic fixture: %s (%0.1fs)\e[0m\n", name, creation_time_in_sec
  end
end

module TestHelpers

  def invoke_sh(cmd,env=nil)
    cmd= cmd.map(&:inspect).join ' ' if cmd.kind_of?(Array)
    env ||= {}
    env['BUNDLE_GEMFILE'] ||= nil
    env['RUBYOPT'] ||= nil

    # Be silent by default
    @quiet_sh= true if @quiet_sh.nil? and not $DEBUG

    @_sh_env,@_sh_cmd = env,cmd
    if @capture_sh or @quiet_sh == true
      # Run quietly and capture output
      require 'open3'
      Open3.popen3 env, cmd do |stdin, stdout, stderr, wait_thr|
        stdin.close
        @_sh_process= wait_thr.value
        @stdout= stdout.read
        @stderr= stderr.read
      end
    else
      # Run with probable-noise
      cmd+= ' >/dev/null' if [true,1].include? @quiet_sh
      cmd+= ' 2>/dev/null' if [true,2].include? @quiet_sh
      @_sh_cmd= cmd
      system env, cmd
      @_sh_process= $?
    end

    @_sh_process.success?
  end

  def invoke_corvid(args='',env=nil)
    args= args.map(&:inspect).join ' ' if args.kind_of?(Array)
    args= args.gsub /^\s+|\s+$/, ''
    cmd= "#{CORVID_BIN_Q} #{args}"
    cmd.gsub! /\n| && /, " && #{CORVID_BIN_Q} "
    invoke_sh cmd, env
  end

  def invoke_rake(args='',env=nil)
    args= args.map(&:inspect).join ' ' if args.kind_of?(Array)
    cmd= "bundle exec rake #{args}"
    invoke_sh cmd, env
  end

  def invoke_sh!    (args,   env=nil) validate_sh_success{ invoke_sh     args,env } end
  def invoke_corvid!(args='',env=nil) validate_sh_success{ invoke_corvid args,env } end
  def invoke_rake!  (args='',env=nil) validate_sh_success{ invoke_rake   args,env } end

  def validate_sh_success
    yield.should be_true
  rescue => e
    puts '>'*60
    puts "ENV: #{@_sh_env}"
    puts "CMD: #{@_sh_cmd}"
    p @_sh_process
    puts
    puts @stdout if @stdout
    puts @stderr if @stderr
    puts '<'*60
    raise e
  end

  def available_tasks_for(cli_name, &cli_block)
    @capture_sh= true
    cli_block.call self
    @stdout.split($/).map{|l| /^\s*#{cli_name} +(\S+).*#.+$/ === l; $1 ? $1.dup : nil}.compact - %w[help]
  end

  def available_tasks_for_corvid
    available_tasks_for 'corvid', &:invoke_corvid!
  end

  def debug_view_dir(options={})
    options= {dir: '.', find: ''}.merge options

    puts '>'*80
    if t= options[:title]
      puts "> #{t}"
      puts '>'*80
    end
    pipe= [options[:pipe],'sort'].flatten.compact.join ' | '
    system "find #{options[:dir].inspect} #{options[:find]} | #{pipe}"
    puts '<'*80
    puts
  end
end

module IntegrationTestDebugDecoration
  SEP1= "\e[0;40;34m#{'_'*120}\e[0m"
  SEP2= "\e[0;40;34m#{'-'*120}\e[0m"
  SEP3= "\e[0;40;34m#{'='*120}\e[0m"
  def self.included spec
    spec.class_eval <<-EOB
      before(:all) { puts ::#{self}::SEP1 }
      before(:each){ puts ::#{self}::SEP2 }
      after(:all)  { puts ::#{self}::SEP3 }
    EOB
  end
end

