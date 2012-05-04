unless defined?(APP_ROOT)
  $stderr.puts "ERROR: APP_ROOT is not defined.\nIt should be defined in your test/bootstrap/all.rb file before loading Corvid."
  exit 1
end

require 'rubygems'

# Load coverage library before Bundler or anything else
require 'corvid/test/simplecov' if ENV['coverage']

def require_if_available(lib)
  require lib
  true
rescue LoadError
  false
end

# Load test dependencies
require 'bundler'
Bundler.require :test

# Add the app's test/ directory to the load path
$:.unshift "#{APP_ROOT}/test"

# Add the app's lib/ directory to the load path
$:.unshift "#{APP_ROOT}/lib"

# Create empty TestHelpers module so that TODO
module TestHelpers
end

# Load test helpers
Dir.glob("#{APP_ROOT}/test/helpers/**/*.rb") {|f| require f}

# Ensure all transactions are rolled back as expected
at_exit do
  if defined?(DB) and DB.respond_to?(:in_transaction?) and DB.in_transaction?
    $stderr.puts(<<-EOB

      !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
      !                                                                              !
      ! Database still in transaction! You've missed a rollback somewhere.           !
      !                                                                              !
      !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

    EOB
    .gsub(/^ +/,''))
  end
end

# TODO Need an after all too? This is only before all
# TODO This should be modularised with options and shit, no?

