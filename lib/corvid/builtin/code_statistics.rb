# Originally copied from Rails 3.2.2.
# https://github.com/rails/rails/blob/master/railties/lib/rails/code_statistics.rb
#
# This file is licenced under the MIT licence.

module Corvid
  module Builtin
    class CodeStatistics

      DEFAULT_FILE_FILTER= /\.(?:rb)$/

      # @param [Hash<String,Hash<Symbol|Object>>] input Key = name. Value = hash of attributes.
      # @option input.values [Symbol] :category The category that the directory contents belong to.
      #   Usually either `:code` or `:test`.
      # @option input.values [Array<String>] :dirs Directories containing files to scan for stats.
      # @option input.values [nil|Regexp|String|Proc] :file_include_filter (DEFAULT_FILE_FILTER) Only files whose
      #   filenames match this filter (using `===`) will be included in the statistics.
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
        puts splitter

        if @total
          print_line("Total", @total)
          puts splitter
        end

        print_summary
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

      def fresh_stats
        { "lines" => 0, "codelines" => 0, "classes" => 0, "methods" => 0, "doco" => 0, "files" => 0 }
      end

      def calculate_directory_statistics(directory, file_filter, file_ignore_filter, line_parser)
        stats = fresh_stats
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

          stats["files"] += 1
          stats[:doc_buf]= 0
          stats[:keep_doc]= false

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
                if /^\s*?#\s*(.*)$/ === line
                  comment= $1
                  if /^@!(group|endgroup|scope|visibility)/ === comment
                    stats["doco"] += 1
                  else
                    stats[:keep_doc] ||= /^@!(?:attribute|macro|method|parse)/ === comment
                    stats[:doc_buf] += 1
                  end
                  block.(stats, line) if block
                else
                  old_cm= [stats["classes"],stats["methods"]]
                  stats["classes"]   += 1 if     /^\s*class\s+[_A-Z]/ === line
                  stats["methods"]   += 1 if     /^\s*def\s+[_a-z]/ === line
                  stats["codelines"] += 1 unless /^\s*?(#|$)/ === line

                  block.(stats, line) if block

                  stats["doco"] += stats[:doc_buf] if stats[:keep_doc] or
                    old_cm != [stats["classes"],stats["methods"]] or # Class/method doc
                    /^\s*module\s+[_A-Z]/ === line or                # Module doc
                    /^\s*[A-Z][A-Za-z0-9_]*\s*=/ === line            # Constant doc
                  stats[:doc_buf] = 0
                  stats[:keep_doc]= false
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
        total = fresh_stats
        @statistics.each_value { |pair| combine_stats! total, pair }
        total
      end

      def sum_stats
        sum = 0
        @statistics.each {|k, v| sum += yield(k,v) || 0 }
        sum
      end

      def print_header
        puts splitter
        puts "| Name                 | Files | Lines |   LOC |   LOD | Classes | Methods | M/C | LOC/M |"
        puts splitter
      end

      def splitter
             "+----------------------+-------+-------+-------+-------+---------+---------+-----+-------+"
      end

      def print_line(name, statistics)
        m_over_c   = (statistics["methods"] / statistics["classes"])   rescue m_over_c = 0
        loc_over_m = (statistics["codelines"] / statistics["methods"]) - 2 rescue loc_over_m = 0

        start = "| #{name.ljust(20)} "

        puts start +
             "| #{statistics["files"].to_s.rjust(5)} " +
             "| #{statistics["lines"].to_s.rjust(5)} " +
             "| #{statistics["codelines"].to_s.rjust(5)} " +
             "| #{statistics["doco"].to_s.rjust(5)} " +
             "| #{statistics["classes"].to_s.rjust(7)} " +
             "| #{statistics["methods"].to_s.rjust(7)} " +
             "| #{m_over_c.to_s.rjust(3)} " +
             "| #{loc_over_m.to_s.rjust(5)} " +
             "|"
      end

      def print_summary
        code_loc = sum_stats{|name,s| s['codelines'] if category_for(name) == :code }
        test_loc = sum_stats{|name,s| s['codelines'] if category_for(name) == :test }
        code_lod = sum_stats{|name,s| s['doco'] if category_for(name) == :code }

        puts center sprintf "Code LOC: %d    Test LOC: %d    Test:Code = %.1f    LOD:LOC = %.1f", \
                      code_loc, test_loc, test_loc.to_f/code_loc, code_lod.to_f/code_loc
        puts
      end

      def center(line)
        "#{' '*[0,(splitter.size-line.size-1)/2].max.to_i}#{line}"
      end

      def category_for(name)
        @input[name][:category]
      end

    end
  end
end
