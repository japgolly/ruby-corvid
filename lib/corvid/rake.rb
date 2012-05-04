unless defined?(APP_ROOT)
  $stderr.puts "ERROR: APP_ROOT is not defined.\nIt should be defined in your Rakefile before loading Corvid."
  exit 1
end

Bundler.require :rake

desc "Delete all generated content."
task :clean do
  dir= "#{APP_ROOT}/target"
  if File.exists?(dir)
    puts "Deleting #{dir}"
    FileUtils.rm_rf dir
  end
end

if Dir.exists?("#{APP_ROOT}/test/unit")
  desc "Run unit tests."
  task :test do
    require 'rake/testtask'
    Rake::TestTask.new(:'test') do |t|
      t.pattern= "#{APP_ROOT}/test{,/*,/**}/*_test.rb"
      t.verbose= true
    end
  end
end

