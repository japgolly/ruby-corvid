#!/usr/bin/env ruby

require './code_statistics'

APP_ROOT= File.expand_path '..', __FILE__
STATS_DIRECTORIES = [
  %w(Libraries          lib),
  %w(Test\ helpers      test/helpers),
  %w(Unit\ tests        test/unit),
  %w(Specifications     test/spec),
  %w(Integration\ tests test/integration),
].collect { |name, dir| [ name, "#{APP_ROOT}/#{dir}" ] }.select { |name, dir| File.directory?(dir) }

CodeStatistics.new(*STATS_DIRECTORIES).to_s

