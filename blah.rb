#!/usr/bin/env ruby

require './code_statistics'

APP_ROOT= File.expand_path '..', __FILE__
STATS_DIRECTORIES = {
  'Libraries'         => { category: :code, dirs: %w[lib] },
  'Test support'      => { category: :test, dirs: %w[test/helpers test/bootstrap] },
  'Unit tests'        => { category: :test, dirs: %w[test/unit] },
  'Specifications'    => { category: :test, dirs: %w[test/spec] },
  'Integration tests' => { category: :test, dirs: %w[test/integration] },
}.each   {|name, data| data[:dirs].map!{|d| "#{APP_ROOT}/#{d}" }}
 .select {|name, data| data[:dirs].any?{|d| File.directory? d }}

Corvid::CodeStatistics.new(STATS_DIRECTORIES).print

