require 'simplecov'
SimpleCov.command_name $coverage_name || 'test'
SimpleCov.coverage_dir 'target/coverage'
SimpleCov.start unless SimpleCov.running

# Ignore lines that make no sense covering
class SimpleCov::SourceFile
  alias :old_process_skipped_lines :process_skipped_lines!
  def process_skipped_lines!
    old_process_skipped_lines
    lines.each do |line|
      # Remove comments and surrounding from line
      # (Actually if a string contains a hash then this will delete everything from that hash onwards BUT that's ok
      # because none of the following scenarios will match anyway.
      l= line.src.sub(/#.+/,'').gsub(/^\s+|\s+$/,'')

      # Skip lines that are nothing but "else", "end", etc
      if (l + ' ') =~ /^((protected|public|private|end|[{}]|else|begin|ensure|rescue)[\s;]+)+$/
        line.skipped!
      # Skip class/module definitions that don't extend (<) or reference anything (.)
      elsif (l + ';') =~ /^((class|module)\s+[^\s;<\(.]+?\s*;\s*)+$/
        line.skipped!
      # Skip method definitions that don't evaluate (=) or reference anything (.)
      elsif l =~ /^def\s+[^\s;\(.]+?([ \(][^);=]+?\)?)?[;\s]*$/
        line.skipped!
      end
    end
  end
end
