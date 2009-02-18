$LOAD_PATH.unshift "../lib"
require 'wee'
require 'wee/components/page_decoration'
require 'wee/components/form_decoration'

require 'rubygems'
require 'rack'
require 'rack/builder'

class Wee::Application
  attr_accessor :path, :description

  def self.applications
    @@applications ||= [] 
  end

  def self.register(path=nil, description=nil)
    app = new { Wee::Session.new(yield, 20) } 
    app.path = path if path
    app.description = description if description
    self.applications << app 
  end
end

class Demo < Wee::Component
  def render(r)
    r.h1 'Wee Demos' 
    r.ul {
      Wee::Application.applications.each do |app|
        r.li {
          r.anchor.href(app.path).with("#{ app.path }: #{ app.description }")
        }
      end
    }
  end
end

Wee::Application.register('/demo', 'This demo application') do 
  Demo.new.add_decoration Wee::PageDecoration.new('Demo')
end

Wee::Application.register('/calc', 'RPN Calculator') do
  require File.join(File.dirname(__FILE__), 'demo', 'calculator')
  Wee::Examples::Calculator.new.
  add_decoration(Wee::FormDecoration.new).
  add_decoration(Wee::PageDecoration.new('RPN Calculator'))
end

Wee::Application.register('/calendar', 'Calendar') do
  require File.join(File.dirname(__FILE__), 'demo', 'calendar')
  CustomCalendarDemo.new
end

Wee::Application.register('/example', 'Misc Components') do
  require File.join(File.dirname(__FILE__), 'demo', 'example')
  MainPage.new
end

app = Rack::Builder.app do
  use Rack::CommonLogger
  use Rack::ShowExceptions
  #use Rack::ShowStatus

  Wee::Application.applications.each do |a|
    map a.path do
      run a
    end
  end
end

require 'rack/handler/webrick'
Rack::Handler::WEBrick.run(app, :Port => 2000)
