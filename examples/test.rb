$LOAD_PATH.unshift "../lib"
require 'rubygems'
require 'wee'
require 'demo/counter'

class MainPage < Wee::Component
  def initialize
    super
    @counters = (1..10).map {|i| add_child Counter.new(i)}
    add_decoration(Wee::PageDecoration.new("Test"))
  end

  def render(r)
    r.page.title("Counter Test").with do 
      @counters.each { |cnt| r.render(cnt); r.break  }
    end
  end
end

if __FILE__ == $0
  Wee.run(MainPage)
end
