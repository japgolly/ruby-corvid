# This is meant to be called from Guardfile directly.
require 'golly-utils/ruby_ext/env_helpers'

def bulk?; ENV.on?('BULK',true) end

def read_rspec_options(app_root)
  rspec_cfg= "#{app_root}/.rspec"
  if File.exists?(rspec_cfg)
    File.read(rspec_cfg)
      .gsub(/#.+?(?:[\r\n]|$)/,' ')             # Remove comments
      .gsub(/\s+/,' ')                          # Join lines and normalise spaces
      .gsub('--order random','--order default') # Disable random order from here
  else
    nil
  end
end

VIM_SWAP_FILES= /^(?:(?:.*[\\\/])?\.[^\\\/]+\.sw[p-z]|.+~)$/
