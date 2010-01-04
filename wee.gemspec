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
  s.description = 
    "Wee is a stateful component-orient web framework which supports "
    "continuations as well as multiple page-states, aka backtracking. "
    "It is largely inspired by Smalltalk's Seaside framework."
  s.add_dependency('rack', '>= 1.0.0')
  s.add_dependency('mspec', '>= 1.5.9')
  s.add_dependency('fast_gettext', '>= 0.4.17')
  s.files = Dir['**/*']
  s.require_path = 'lib'
  s.author = "Michael Neumann"
  s.email = "mneumann@ntecs.de"
  s.homepage = "http://rubyforge.org/projects/wee"
  s.rubyforge_project = "wee"
end
