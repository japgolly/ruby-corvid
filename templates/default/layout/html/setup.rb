 def javascripts
   # Load the existing javascripts while appending the custom one
   super + %w(js/custom.js)
 end

