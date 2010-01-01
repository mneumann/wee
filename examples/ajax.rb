$LOAD_PATH.unshift "../lib"
require 'rubygems'
require 'wee'
require 'rack'
require 'wee/jquery'

class AjaxCounter < Wee::Component
  def initialize
    super
    @counter = 0
  end

  def state(s)
    super
    s.add_ivar(self, :@counter, @counter)
  end

  def render(r)
    r.once(self.class) {
      r.css "div.wee-AjaxCounter a { border: 1px solid blue; padding: 5px; background-color: #ABABAB; };"
    }
    r.div.css_class('wee-AjaxCounter').oid.with {
      r.anchor.update_component_on(:click) { @counter += 1 }.with(@counter.to_s)
    }
  end
end

class HelloWorld < Wee::RootComponent
  def title
    'Wee + Ajax'
  end

  def javascripts
    Wee::JQuery.javascript_includes
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
  puts
  puts "Open your browser at: http://localhost:2000/ajax"
  puts
  Wee.run HelloWorld, :mount_path => '/ajax', :additional_mounts => {'/jquery' => Wee::JQuery.method(:install)}
end
