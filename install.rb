require 'rbconfig'
require 'ftools'

dst_dir = Config::CONFIG['sitelibdir']
Dir.chdir('lib') { 
  Dir['**/*.rb'].each {|file|
    File.mkpath File.join(dst_dir, File.dirname(file)), true
    File.install file, File.join(dst_dir, file), 0644, true
  }
}
