require 'rbconfig'
require 'ftools'

# Install lib
dst_dir = Config::CONFIG['sitelibdir']
Dir.chdir('lib') { 
  Dir['**/*'].reject {|f| f =~ /\.svn($|\/)/ or not File.file?(f) }.each {|file|
    File.mkpath File.join(dst_dir, File.dirname(file)), true
    File.install file, File.join(dst_dir, file), 0644, true
  }
}

# Install bin
File.install 'bin/wee', File.join(Config::CONFIG['bindir'], 'wee'), 0755, true
