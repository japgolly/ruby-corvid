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
      all= {}
      @input.each do |name,data|
        data[:dirs].each do |dir|

          # Get stats for a single dir
          new_stats= calculate_directory_statistics(dir,
                       data[:file_include_filter] || DEFAULT_FILE_FILTER,
                       data[:file_exclude_filter]
                     )

          if existing= all[name]
            # Combine results
            keys= (existing.keys + new_stats.keys).uniq
            keys.each do |key|
              existing[key] ||= 0
              existing[key] += (new_stats[key] || 0)
            end
          else
            # Save results
            all[name]= new_stats
          end

        end
      end
      all
    end

    def calculate_directory_statistics(directory, file_filter = DEFAULT_FILE_FILTER, file_ignore_filter = nil)
      stats = { "lines" => 0, "codelines" => 0, "classes" => 0, "methods" => 0 }

      Dir.foreach(directory) do |file_name|
        if File.directory?(directory + "/" + file_name) and (/^\./ !~ file_name)
          newstats = calculate_directory_statistics(directory + "/" + file_name, file_filter, file_ignore_filter)
          stats.each { |k, v| stats[k] += newstats[k] }
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
          stats["classes"]   += 1 if line =~ /^\s*class\s+[_A-Z]/
          stats["methods"]   += 1 if line =~ /^\s*def\s+[_a-z]/
          stats["codelines"] += 1 unless line =~ /^\s*$/ || line =~ /^\s*#/
        end
      end

      stats
    end

    def calculate_total
      total = { "lines" => 0, "codelines" => 0, "classes" => 0, "methods" => 0 }
      @statistics.each_value { |pair| pair.each { |k, v| total[k] += v } }
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
      puts "| Name                 | Lines |   LOC | Classes | Methods | M/C | LOC/M |"
      print_splitter
    end

    def print_splitter
      puts "+----------------------+-------+-------+---------+---------+-----+-------+"
    end

    def print_line(name, statistics)
      m_over_c   = (statistics["methods"] / statistics["classes"])   rescue m_over_c = 0
      loc_over_m = (statistics["codelines"] / statistics["methods"]) - 2 rescue loc_over_m = 0

      start = "| #{name.ljust(20)} "

      puts start +
           "| #{statistics["lines"].to_s.rjust(5)} " +
           "| #{statistics["codelines"].to_s.rjust(5)} " +
           "| #{statistics["classes"].to_s.rjust(7)} " +
           "| #{statistics["methods"].to_s.rjust(7)} " +
           "| #{m_over_c.to_s.rjust(3)} " +
           "| #{loc_over_m.to_s.rjust(5)} |"
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
