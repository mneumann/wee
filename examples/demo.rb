$LOAD_PATH.unshift "../lib"
require 'wee'
require 'rubygems'
require 'rack'
require 'rack/builder'

APPS = []

class Demo < Wee::Component
  def render(r)
    r.h1 'Wee Demos' 
    r.ul {
      APPS.each do |name, descr, _| 
        r.li {
          r.anchor.href("/#{ name }").with("/#{ name }: #{ descr }")
        }
      end
    }
  end
end

class RackHandler
  def initialize(description, &block)
    @description = description
    @block = block
    @application = Wee::Application.new {|app|
      app.default_request_handler {
        Wee::Session.new(block.call, 20)
      }
    }
  end

  def call(env)
    context = Wee::Context.new(Wee::Request.new(env))
    @application.handle_request(context)
    return context.response.finish
  end
end


def APPS.add(name, description=nil, &block)
  self << [name, description||name, block]
end

APPS.add 'demo', 'This demo application' do 
  Demo.new.add_decoration Wee::PageDecoration.new('Demo')
end

APPS.add 'calc', 'RPN Calculator' do
  require 'wee/examples/calculator'
  Wee::Examples::Calculator.new.
  add_decoration(Wee::FormDecoration.new).
  add_decoration(Wee::PageDecoration.new('RPN Calculator'))
end

APPS.add 'calendar', 'Calendar' do
  require File.join(File.dirname(__FILE__), 'demo', 'calendar')
  CustomCalendarDemo.new
end

APPS.add 'example', 'Misc Components' do
  require File.join(File.dirname(__FILE__), 'demo', 'example')
  MainPage.new
end

app = Rack::Builder.app do
  use Rack::CommonLogger
  APPS.each do |name, descr, block|
    map "/#{name}" do
      run RackHandler.new('This demo application', &block)
    end
  end
end

require 'rack/handler/webrick'
Rack::Handler::WEBrick.run(app, :Port => 2000)
