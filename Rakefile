require "bundler/gem_tasks"
require "rake/testtask"

task :default => :spec

Rake::TestTask.new do |t|
  t.libs << "lib"
  t.test_files = FileList['test/test_*.rb']
  t.verbose = true
end
