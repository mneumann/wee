require 'rake/rdoctask'
require 'rake/testtask'

Rake::RDocTask.new do |rd|
  rd.main = "README"
  rd.rdoc_dir = 'doc/tmp'
  rd.rdoc_files.include('lib/**/*.rb', 'README', 'INSTALL')
  rd.options << '--all --inline-source' 
end

task :rdoc do
  sh 'cpdup -o doc/tmp doc/rdoc' 
end

Rake::TestTask.new do |t|
  t.test_files = FileList['test/test*.rb']
  t.verbose = true
end

task :package do
  sh 'gem build wee.gemspec' 
end

task :local_install => [:package] do
  sh 'gem uninstall wee || true'
  sh 'gem install wee-*.gem'
end

task :clean => [:clobber_rdoc]

task :default => [:test, :rdoc, :clean]
