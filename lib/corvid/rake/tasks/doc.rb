require 'yard'

YARD::Rake::YardocTask.new(:doc)

namespace :doc do
  def get_doc_output_dirs
    yardopts= File.read("#{APP_ROOT}/.yardopts").gsub(/[\r\n]+/,' ')
    %w[db output-dir].map do |opt_key|
      if yardopts =~ /--#{opt_key}\s+(.+?)(?:\s|$)/
        $1
      end
    end.compact
  end

  task :clean do
    get_doc_output_dirs.each do |dir|
      full_dir= File.join(APP_ROOT,dir)
      if File.exists?(full_dir)
        puts "Deleting #{dir}"
        FileUtils.rm_rf full_dir
      end
    end
  end
end

namespace :clean do
  task :doc => 'doc:clean'
end
