desc "Report code statistics"
task :stats do
  require 'corvid/builtin/code_statistics'

  # TODO Stats dirs currently hardcoded. Probably best to read from .corvid/stats_dirs.(rb|yml) or something.
  stats_cfg= {
    'Library code'      => { category: :code, dirs: %w[lib] },
    'Test support'      => { category: :test, dirs: %w[test/helpers test/bootstrap test/factories test/support] },
    'Unit tests'        => { category: :test, dirs: %w[test/unit] },
    'Specifications'    => { category: :test, dirs: %w[test/spec], line_parser: :spec },
    'Integration tests' => { category: :test, dirs: %w[test/integration], line_parser: :spec },
  }

  stats_cfg= stats_cfg.each   {|name, data| data[:dirs].map!{|d| "#{APP_ROOT}/#{d}" }}
                      .select {|name, data| data[:dirs].any?{|d| File.directory? d }}
  Corvid::CodeStatistics.new(stats_cfg).print
end

