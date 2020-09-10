require 'wee'
require 'rack'

class AjaxCounter < Wee::Component

  #require 'wee/jquery'
  #def self.depends; [Wee::JQuery] end

  require 'wee/rightjs'
  def self.depends; [Wee::RightJS] end

  def initialize
    @counter = 0
  end

  def state(s)
    super
    s.add_ivar(self, :@counter, @counter)
  end

=begin
  def style
    "div.wee-AjaxCounter a { border: 1px solid blue; padding: 5px; background-color: #ABABAB; };"
  end

  def render(r)
    r.render_style(self)
    r.div.css_class('wee-AjaxCounter').oid.with {
      r.anchor.update_component_on(:click) { @counter += 1 }.with(@counter.to_s)
    }
  end
=end

  def render(r)
    r.anchor.oid.update_component_on(:click) { @counter += 1 }.with(@counter.to_s)
  end

end

class HelloWorld < Wee::RootComponent

  def self.depends; [AjaxCounter.depends] end

  def title
    'Wee + Ajax'
  end

  def initialize
    @counters = (1..10).map { AjaxCounter.new }
  end

  def children() @counters end

  def render(r)
    render_hello(r)
    r.div.callback_on(:click) { p "refresh" }.with("Refresh")
    @counters.each {|c| r.render(c); r.break}
  end

  def render_hello(r)
    @hello ||= "Hello"
    r.div.id("hello").update_on(:click) {|r|
      @hello.reverse!
      render_hello(r)
    }.with(@hello)
  end
end

if __FILE__ == $0
  Wee.run HelloWorld, :mount_path => '/ajax', :print_message => true
end
