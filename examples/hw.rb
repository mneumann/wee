$LOAD_PATH.unshift "../lib"
require 'rubygems'
require 'wee'

class HelloWorld < Wee::Component
  def initialize
    super
    add_decoration(Wee::PageDecoration.new("Hello World"))
  end

  def render(r)
    r.h1 "Hello World from Wee!"
  end
end

Wee.run(HelloWorld) if __FILE__ == $0
