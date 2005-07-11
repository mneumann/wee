require 'wee'
require 'wee/adaptors/webrick'
require 'wee/utils'

class Demo < Wee::Component
  def render
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

APPS = []
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

APPS.each do |name, descr, block|
  Wee::WEBrickAdaptor.register("/#{ name }" => Wee::Utils.app_for(&block))
end
Wee::WEBrickAdaptor.start
