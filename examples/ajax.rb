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
      r.anchor.onclick_update_self_callback { @counter += 1 }.with(@counter.to_s)
    }
  end
end

class HelloWorld < Wee::Component
  def initialize
    super
    @counters = (1..10).map { AjaxCounter.new }
  end

  def children() @counters end

  def render(r)
    r.html {
      r.head {
        r.title('Wee + Ajax')
        Wee::JQuery.javascript_includes(r)
      }
      r.body {
        render_hello(r)
        r.div.onclick_callback { p "refresh" }.with("Refresh")
        @counters.each {|c| r.render(c); r.break}
      }
    }
  end

  def render_hello(r)
    @hello ||= "Hello"
    r.div.id("hello").onclick_update_callback {|r|
      @hello.reverse!
      render_hello(r)
    }.with(@hello)
  end
end

if __FILE__ == $0
  require 'rack/handler/webrick'
  app = Rack::Builder.app do
    Wee::JQuery.install('/jquery', self)
    map '/ajax' do
      run Wee::Application.new {
        Wee::Session.new(HelloWorld.new)
      }
    end
  end
  puts
  puts "Open your browser at: http://localhost:2000/ajax"
  puts
  Rack::Handler::WEBrick.run(app, :Port => 2000)
end
