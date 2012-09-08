# encoding: utf-8
APP_ROOT = File.expand_path('../../..',__FILE__)
require 'rubygems'
require 'bundler/setup'
require 'corvid/test/bootstrap/all'

Bundler.require :default

# Load test helpers
Dir.glob("#{APP_ROOT}/test/helpers/**/*.rb") {|f| require f}

