#!/usr/bin/env ruby

require './code_statistics'

APP_ROOT= File.expand_path '..', __FILE__
STATS_DIRECTORIES = {
  'Library'           => { category: :code, dirs: %w[lib] },
  'Test support'      => { category: :test, dirs: %w[test/helpers test/bootstrap test/factories test/support] },
  'Unit Tests'        => { category: :test, dirs: %w[test/unit] },
  'Specifications'    => { category: :test, dirs: %w[test/spec], line_parser: :spec },
  'Integration Tests' => { category: :test, dirs: %w[test/integration], line_parser: :spec },
}#.each   {|name, data| data[:dirs].map!{|d| "#{APP_ROOT}/#{d}" }}
 .select {|name, data| data[:dirs].any?{|d| File.directory? d }}

Corvid::CodeStatistics.new(STATS_DIRECTORIES).print

