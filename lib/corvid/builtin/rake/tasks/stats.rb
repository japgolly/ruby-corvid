desc "Report code statistics"
task :stats do
  require 'corvid/builtin/code_statistics'

  # Default stats config
  defaults= {
    'Library code'      => { category: :code, dirs: %w[lib] },
    'Test support'      => { category: :test, dirs: %w[test/helpers test/bootstrap test/factories test/support] },
    'Unit tests'        => { category: :test, dirs: %w[test/unit] },
    'Specifications'    => { category: :test, dirs: %w[test/spec], line_parser: :spec },
    'Integration tests' => { category: :test, dirs: %w[test/integration], line_parser: :spec },
  }

  # Load external stats config
  stats_cfg= nil
  file= "#{APP_ROOT}/.corvid/stats_cfg.rb"
  if File.exists? file
    o= Object.new
    o.instance_eval "def defaults; @defaults end"
    o.instance_variable_set :@defaults, defaults
    stats_cfg= o.instance_eval File.read(file)
  end

  # Pre-process stats config
  stats_cfg ||= defaults
  stats_cfg= stats_cfg.each   {|name, data| data[:dirs].map!{|d| "#{APP_ROOT}/#{d}" }}
                      .select {|name, data| data[:dirs].any?{|d| File.directory? d }}

  # Generate stats
  Corvid::CodeStatistics.new(stats_cfg).print
end
