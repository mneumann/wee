$LOAD_PATH.unshift "../lib"
require 'rubygems'
require 'wee'
require 'wee/components/page_decoration'
require 'rack'

class HelloWorld < Wee::Component
  def initialize
    super
    add_decoration(Wee::PageDecoration.new("Hello World"))
  end

  def render(r)
    r.h1 "Hello World from Wee!"
  end
end

if __FILE__ == $0
  require 'rack/handler/webrick'
  app = Rack::Builder.app do
    map '/' do
      run Wee::Application.new {
        Wee::Session.new(HelloWorld.new)
      }
    end
  end
  Rack::Handler::WEBrick.run(app, :Port => 2000)
end
