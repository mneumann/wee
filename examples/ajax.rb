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

  def backtrack(state)
    super
    state.add_ivar(self, :@counter, @counter)
  end

  def render(r)
    r.div.oid.onclick_update_self_callback { @counter += 1 }.with(@counter.to_s)
  end
end

class HelloWorld < Wee::Component
  def initialize
    super
    @cs = (1..10).map { add_child AjaxCounter.new }
  end

  def render(r)
    r.html {
      r.head {
        r.title('Wee + Ajax')
        Wee::JQuery.javascript_includes(r)
      }
      r.body {
        r.div.onclick_callback { p "refresh" }.with("Refresh")
        @cs.each {|c| r.render(c); r.break}
      }
    }
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
  Rack::Handler::WEBrick.run(app, :Port => 2000)
end
