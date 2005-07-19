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

task :gem_install => [:package] do
  sh '(yes | gem uninstall wee) || true'
  sh 'gem install --no-rdoc wee-*.gem'
end

task :install do
  ruby 'install.rb'
end

task :tag do
  if File.read('lib/wee.rb') =~ /Version\s+=\s+"(\d+\.\d+\.\d+)"/
    version = $1
  else
    raise "no version"
  end
  baseurl = "svn+ssh://ntecs.de/data/projects/svn/public/Wee"

  sh "svn cp -m 'tagged #{ version }' #{ baseurl }/trunk #{ baseurl }/tags/wee-#{ version }"
end

task :clean => [:clobber_rdoc]

task :default => [:test, :rdoc, :clean]
