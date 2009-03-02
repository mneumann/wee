$LOAD_PATH.unshift "../lib"
require 'rubygems'
require 'wee'

$LOAD_PATH.unshift "./demo"
require 'demo/calculator'
require 'demo/counter'
require 'demo/calendar'
require 'demo/radio'

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
    @components << E.new(RadioTest.new, "Radio Buttons", 'demo/radio.rb')

    @selected_component = @components.first

    @components.each {|c| add_child c.component }

    @show_sourcecode = false
  end

  def render(r)
    r.h1 'Wee Component Demos' 
    r.div.style('float: left; width: 200px;').with {
      r.select_list(@components).
        labels(@components.map {|c| c.title}).
        selected(@selected_component).
        size(10).
        onclick_javascript("this.form.submit()").
        callback {|ch| @selected_component = ch }
      r.break
      r.checkbox.checked(@show_sourcecode).
        onclick_javascript("this.form.submit()").
        callback {|bool| @show_sourcecode = bool }
      r.space
      r.text "Show Sourcecode?"
      r.break
    }
    r.div.style('float: left; left: 20px; height: 200px; width: 600px; background: #EFEFEF; border: 1px dotted red; padding: 10px').with {
      r.render @selected_component.component
    }
    if @show_sourcecode
      r.div.style('float: left; margin-top: 2em; border-top: 2px solid; background: #FEFEFE; width: 100%').with {
        r.pre { r.encode_text(File.read(@selected_component.file)) }
      }
    end
  end
end

Wee.run(Demo) if __FILE__ == $0
