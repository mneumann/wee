require 'rake/rdoctask'

Rake::RDocTask.new do |rd|
  rd.main = "README"
  rd.rdoc_dir = 'doc/tmp'
  rd.rdoc_files.include('lib/**/*.rb', 'README', 'INSTALL')
  rd.options << '--all --inline-source' 
end

task :rdoc do
  sh 'cpdup -o doc/tmp doc/rdoc' 
end

task :test do
  sh 'mspec -I./lib -f s test/component_spec.rb'
end

task :package do
  sh 'gem build wee.gemspec' 
end

task :clean => [:clobber_rdoc]

task :default => [:test, :rdoc, :clean]
