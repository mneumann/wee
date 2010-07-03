require 'rake/rdoctask'

Rake::RDocTask.new do |rd|
  rd.main = "README.rdoc"
  rd.rdoc_dir = 'doc/rdoc'
  rd.rdoc_files.include('lib/**/*.rb', 'README.rdoc')
  rd.options << '--inline-source' 
  rd.options << '--all' 
  rd.options << '--accessor=html_attr=HtmlAttribute'
  rd.options << '--accessor=generic_tag=GenericTagBrush'
  rd.options << '--accessor=generic_single_tag=GenericSingleTagBrush'
  rd.options << '--accessor=brush_tag=Brush'
end

task :test do
  sh 'mspec -I./lib -f s test/component_spec.rb'
end

task :install do
  sh 'sudo gem install wee-2.2.0.gem'
end


task :package do
  sh 'gem build wee.gemspec' 
end

task :clean => [:clobber_rdoc]

task :default => [:test, :rdoc, :clean]
