module Corvid
  module EnvHelpers

    def boolean(key, default=nil)
      return default unless self.has_key?(key)
      v= self[key]
      return true if v =~ /^\s*(?:[1yt]|yes|true|on|enabled?)\s*$/i
      return false if v =~ /^\s*(?:[0nf]|no|false|off|disabled?)\s*$/i
      STDERR.puts "Unable to parse boolean value #{v.inspect} for key #{key.inspect}."
      default
    end

    alias yes? boolean
    alias on? boolean
    alias enabled? boolean

    def no?(key, default=nil)
      !boolean(key, default)
    end
    alias off? no?
    alias disabled? no?

  end
end

# Add helpers to ENV
ENV.send :extend, Corvid::EnvHelpers
