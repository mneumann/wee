require 'rubygems'

if File.read('lib/wee.rb') =~ /Version\s+=\s+"(\d+\.\d+\.\d+)"/
  version = $1 
else
  raise "no version"
end

spec = Gem::Specification.new do |s|
  s.name = 'wee'
  s.version = version 
  s.summary = 'Wee is a framework for building highly dynamic web applications.'

  s.files = Dir['**/*']

  s.require_path = 'lib'

  s.author = "Michael Neumann"
  s.email = "mneumann@ntecs.de"
  s.homepage = "http://rubyforge.org/projects/wee"
  s.rubyforge_project = "wee"
end
