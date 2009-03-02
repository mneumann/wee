$LOAD_PATH.unshift "../lib"
require 'rubygems'
require 'wee'

$LOAD_PATH.unshift "./demo"
require 'demo/calculator'
require 'demo/counter'
require 'demo/calendar'

class Demo < Wee::Component
  class E < Struct.new(:component, :title, :file); end

  def initialize
    super
    add_decoration Wee::PageDecoration.new('Wee Demos')
    add_decoration Wee::FormDecoration.new

    @components = [] 
    @components << E.new(Counter.new, "Counter", 'demo/counter.rb')
    @components << E.new(Calculator.new, "Calculator", 'demo/calculator.rb')
    @components << E.new(CustomCalendarDemo.new, "Calendar", 'demo/calendar.rb')

    @selected_component = @components.first

    @components.each {|c| add_child c.component }
  end

  def render(r)
    r.h1 'Wee Component Demos' 
    r.div.style('float: left; width: 100px;').with {
      r.select_list(@components).
        labels(@components.map {|c| c.title}).
        selected(@selected_component).
        size(10).
        onclick_javascript("this.form.submit()").
        callback {|ch| @selected_component = ch }
    }

    r.div.style('float: left; left: 20px; height: 200px; width: 600px; background: #EFEFEF; border: 1px dotted red; padding: 10px').with {
      r.render @selected_component.component
    }
  end
end

Wee.run(Demo) if __FILE__ == $0
