require 'rubygems'
require 'wee'
require 'wee/adaptors/webrick' 
require 'wee/utils'

class HelloWorld < Wee::Component
  def initialize
    super
    add_decoration(Wee::PageDecoration.new("Hello World"))
  end

  def render
    r.h1 "Hello World from Wee!"
  end
end

Wee::WEBrickAdaptor.register('/app' => Wee::Utils.app_for(HelloWorld)).start 
