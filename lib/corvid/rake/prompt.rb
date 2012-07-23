def prompt(msg)
  STDERR.print "#{msg} [yn]: "
  while true
    case STDIN.gets.chomp!
    when /^\s*(y(es)?)?\s*$/i then return true
    when /^\s*no?\s*$/i then return false
    else
      STDERR.print "Sorry, I don't understand. Please type y or n: "
    end
  end
end

