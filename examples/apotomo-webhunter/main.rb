$LOAD_PATH.unshift '../../lib'
require 'rubygems'
require 'wee'

class BearTrap < Wee::Component
  attr_accessor :mouse

  def initialize(is_charged=true)
    @charged = is_charged
    add_decoration Wee::OidDecoration.new
  end

  def render(r)
    img = @charged ? 'charged' : 'snapped'
    brush = r.div.id('bear_trap').style("background: transparent url('/images/bear_trap_#{img}.png');")
    if @charged
      if @over
        brush.update_on(:mouseout) {|r|
          @over = false
          r.render(self)
        }
      else
        brush.update_on(:mouseover) {|r|
          @over = true
          @mouse.update(r)
          if @mouse.cheese_count >= 3
            @charged = false
          end
          r.render(self)
          r.javascript("alert('gotcha')") unless @charged
        }
      end
    end
    brush.with { r.image.src('/images/cheese.png').id('cheese') }
  end
end

class Mouse < Wee::Component
  attr_reader :cheese_count

  def initialize(cheese_count=0)
    @cheese_count = cheese_count
  end

  def render(r)
    r.image.src("/images/mouse.png").id("mouse").width(90 * (@cheese_count+1))
  end

  def update(r)
    @cheese_count += 1
    r.render(self)
  end
end

class Main < Wee::Component
  def initialize
    super
    add_decoration Wee::PageDecoration.new('A dark forest...', %w(/stylesheets/forest.css),
      %w(/javascripts/jquery-1.3.2.min.js /javascripts/wee-jquery.js))
    @trap = BearTrap.new(true)
    @mouse = Mouse.new
    @trap.mouse = @mouse 
  end

  def children() [@trap, @mouse] end

  def render(r)
    r.div.id('forest').with {
      r.render @trap
      r.render @mouse
    }
  end
end

Wee.run(Main, '/', 2000, 'public') if __FILE__ == $0
