require 'wee'
require 'wee/adaptors/nitro'
require 'wee/examples/calculator'
require 'wee/examples/window'

require 'rubygems'
require 'nitro'
require 'nitro/controller'

class MyComponent < Wee::Component
  def initialize
    super
    add_decoration(Wee::FormDecoration.new)
    add_decoration(Wee::PageDecoration.new('Hello from Wee/Nitro!'))

    @windows = (0..2).map {|i|
      Wee::Examples::Window.new {|w|
        w.title = 'Calculator'
        w.pos_y = (i*200).to_s + "px"
        w.child = Wee::Examples::Calculator.new
      }
    }
  end

  def children
    @windows
  end

  def render
    @windows.each {|window| r.render window}
  end
end

class AppController < Nitro::Controller
  include Wee::Nitro::ControllerMixin

  scaffold_with_component do
    MyComponent.new
  end
end

Nitro.run(:host => '127.0.0.1', :port => 9999, :dispatcher => Nitro::Dispatcher.new('/app' => AppController))
