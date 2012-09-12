# Originally copied from Rails 3.2.2.
# https://github.com/rails/rails/blob/master/railties/lib/rails/code_statistics.rb
#
# This file is licenced under the MIT licence.

module Corvid
class CodeStatistics

  DEFAULT_FILE_FILTER= /\.(?:rb)$/

  # @param [Hash<String,Hash<Symbol|Object>>] input Key = name. Value = hash of attributes.
  # @option input.values [Symbol] :category The category that the directory contents belong to. Usually either `:code`
  #   or `:test`.
  # @option input.values [Array<String>] :dirs Directories containing files to scan for stats.
  # @option input.values [nil|Regexp|String|Proc] :file_include_filter (DEFAULT_FILE_FILTER) Only files whose filenames
  #   match this filter (using `===`) will be included in the statistics.
  # @option input.values [nil|Regexp|String|Proc] :file_exclude_filter (nil) Files whose filenames match this filter
  #   (using `===`) will be excluded from the statistics.
  # @option input.values [Symbol|Proc] :line_parser (:ruby)
  def initialize(input)
    @input      = input
    @statistics = calculate_statistics
    @total      = calculate_total if @input.size > 1
  end

  def print
    print_header
    @input.keys.each {|name| print_line name, @statistics[name] }
    print_splitter

    if @total
      print_line("Total", @total)
      print_splitter
    end

    print_code_test_stats
  end

  private
    def calculate_statistics
      all = {}
      @input.each do |name,data|
        data[:dirs].each do |dir|

          # Get stats for a single dir
          new_stats= calculate_directory_statistics(dir,
                       data[:file_include_filter] || DEFAULT_FILE_FILTER,
                       data[:file_exclude_filter],
                       data[:line_parser] || :ruby
                     )

          # Save results
          if existing= all[name]
            combine_stats! existing, new_stats
          else
            all[name] = new_stats
          end

        end
      end
      all
    end

    def combine_stats!(existing, new_stats)
      keys= (existing.keys + new_stats.keys).uniq
      keys.each do |key|
        existing[key] ||= 0
        existing[key] += (new_stats[key] || 0)
      end
      existing
    end

    def calculate_directory_statistics(directory, file_filter, file_ignore_filter, line_parser)
      stats = { "lines" => 0, "codelines" => 0, "classes" => 0, "methods" => 0 , doc_buf: 0, "cm_doco" => 0 }
      line_parser = LINE_PARSERS[line_parser] if line_parser.is_a? Symbol

      Dir.foreach(directory) do |file_name|
        next if /^\.{1,2}$/ === file_name
        full_name = directory + "/" + file_name
        if File.directory? full_name
          newstats = calculate_directory_statistics full_name, file_filter, file_ignore_filter, line_parser
          combine_stats! stats, newstats
        end

        next unless file_filter.nil? || file_filter === file_name
        next if file_ignore_filter && file_ignore_filter === file_name

        f = File.open(directory + "/" + file_name)
        comment_started = false
        while line = f.gets
          stats["lines"]     += 1
          if(comment_started)
            if line =~ /^=end/
              comment_started = false
            end
            next
          else
            if line =~ /^=begin/
              comment_started = true
              next
            end
          end
          line_parser.call stats, line
        end
      end if File.directory? directory

      stats
    end

    LINE_PARSERS = {
      ruby: lambda {|stats, line, &block|
              if /^\s*?#/ === line
                stats[:doc_buf] += 1
                block.(stats, line) if block
              else
                cm1= [stats["classes"],stats["methods"]]

                stats["classes"]   += 1 if /^\s*class\s+[_A-Z]/ === line
                stats["methods"]   += 1 if /^\s*def\s+[_a-z]/ === line
                stats["codelines"] += 1 unless /^\s*?(#|$)/ === line
                block.(stats, line) if block

                cm2= [stats["classes"],stats["methods"]]
                stats["cm_doco"] += stats[:doc_buf] if cm1 != cm2 or /^\s*module\s+[_A-Z]/ === line
                stats[:doc_buf] = 0
              end
            },

      spec: lambda {|stats, line, &block|
              LINE_PARSERS[:ruby].(stats, line) {
                stats["classes"] += 1 if /^\s*?describe[(\s]/ === line
                stats["methods"] += 1 if /^\s*?it[(\s]/ === line
                block.(stats, line) if block
              }
            },

      nop: lambda{|stats, line, &block|},
    }

    def calculate_total
      total = { "lines" => 0, "codelines" => 0, "classes" => 0, "methods" => 0, "cm_doco" => 0 }
      @statistics.each_value { |pair| combine_stats! total, pair }
      total
    end

    def calculate_code
      code_loc = 0
      @statistics.each { |k, v| code_loc += v['codelines'] unless in_test_category? k }
      code_loc
    end

    def calculate_tests
      test_loc = 0
      @statistics.each { |k, v| test_loc += v['codelines'] if in_test_category? k }
      test_loc
    end

    def print_header
      print_splitter
      puts "| Name                 | Lines |   LOC | LOD(MC) | Classes | Methods | M/C | LOC/M |"
      print_splitter
    end

    def print_splitter
      puts "+----------------------+-------+-------+---------+---------+---------+-----+-------+"
    end

    def print_line(name, statistics)
      m_over_c   = (statistics["methods"] / statistics["classes"])   rescue m_over_c = 0
      loc_over_m = (statistics["codelines"] / statistics["methods"]) - 2 rescue loc_over_m = 0

      start = "| #{name.ljust(20)} "

      puts start +
           "| #{statistics["lines"].to_s.rjust(5)} " +
           "| #{statistics["codelines"].to_s.rjust(5)} " +
           "| #{statistics["cm_doco"].to_s.rjust(7)} " +
           "| #{statistics["classes"].to_s.rjust(7)} " +
           "| #{statistics["methods"].to_s.rjust(7)} " +
           "| #{m_over_c.to_s.rjust(3)} " +
           "| #{loc_over_m.to_s.rjust(5)} " +
           "|"
    end

    def print_code_test_stats
      code  = calculate_code
      tests = calculate_tests

      puts "  Code LOC: #{code}     Test LOC: #{tests}     Code to Test Ratio: 1 : #{sprintf("%.1f", tests.to_f/code)}"
      puts ""
    end

    def category_for(name)
      @input[name][:category]
    end

    def in_test_category?(name)
      category_for(name) == :test
    end
end
end
