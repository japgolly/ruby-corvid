def add_files_to_coverage(glob_pattern, coverage_results=nil)
  coverage_results ||= SimpleCov.result

  # Find new files
  new_files= Dir[glob_pattern].map{|f| File.expand_path f} - coverage_results.files.map(&:filename)

  # Map each file to an array of 0s for LOC and nils for empty (or comment-only) lines
  nr= {}
  new_files.each{|f| nr[f]= File.readlines(f).map{|l| /^\s*(?:#.*)?$/ === l ? nil : 0}}

  # Merge with existing result
  r2= SimpleCov::Result.new nr.merge(coverage_results.original_result)
  r2.created_at= coverage_results.created_at
  r2.command_name= coverage_results.command_name

  r2
end

def add_files_to_coverage_at_exit(glob_pattern)
  SimpleCov.at_exit do
    r2= add_files_to_coverage(glob_pattern)
    #SimpleCov.class.instance_variable_set :@result, r2
    r2.format!
  end
end

require 'simplecov'
SimpleCov.command_name $coverage_name || 'test'
SimpleCov.coverage_dir 'target/coverage'
SimpleCov.start unless SimpleCov.running

# Ignore lines that make no sense covering
class SimpleCov::SourceFile
  alias :old_process_skipped_lines :process_skipped_lines!
  def process_skipped_lines!
    old_process_skipped_lines
    lines.each {|line|
      # Remove comments and surrounding from line
      # (Actually if a string contains a hash then this will delete everything from that hash onwards BUT that's ok
      # because none of the following scenarios will match anyway.
      l= line.src.sub(/#.+/,'').gsub(/^\s+|\s+$/,'')

      # Skip lines that are nothing but "else", "end", etc
      if /^((protected|public|private|end|[{}]|else|begin|ensure|rescue)[\s;]+)+$/ === (l + ' ')
        line.skipped!
      # Skip class/module definitions that don't extend (<) or reference anything (.)
      elsif /^((class|module)\s+[^\s;<\(.]+?\s*;\s*)+$/ === (l + ';')
        line.skipped!
      # Skip method definitions that don't evaluate (=) or reference anything (.)
      elsif /^def\s+[^\s;\(.]+?([ \(][^);=]+?\)?)?[;\s]*$/ === l
        line.skipped!
      end
    }
  end
end
