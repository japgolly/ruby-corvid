desc "Delete all generated content."
task :clean do
  dir= "#{APP_ROOT}/target"
  if File.exists?(dir)
    puts "Deleting #{dir}"
    FileUtils.rm_rf dir
  end
end

