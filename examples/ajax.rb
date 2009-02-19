$LOAD_PATH.unshift "../lib"
require 'rubygems'
require 'wee'
require 'rack'

class UpdateComponent < Wee::Component
  def initialize
    super
    @counter = 0
  end

  def backtrack(state)
    super
    state.add_ivar(self, :@counter, @counter)
  end

  def render(r)
    r.div.id("wee_#{self.object_id}").with {
      r.div.onclick_update_multi {
        @counter += 1
        redraw(r, self)
      }.with(@counter.to_s)
    }
  end

  def redraw(rold, *components)
    r = Wee::Renderer.new
    r.request   = rold.request
    r.response  = Wee::Response.new
    # replace all callbacks of those components 
    r.callbacks = rold.callbacks # Wee::Callbacks.new
    r.document  = Wee::HtmlWriter.new(r.response)

    components.each do |c|
      r.render_decoration(c)
=begin
      begin
        c.decoration.render_on(r)
      ensure
        r.close
      end
=end
    end

    session.send_response(r.response)
  end
end

class HelloWorld < Wee::Component

  def initialize
    super
    @cs = (1..10).map { add_child UpdateComponent.new }
  end

  def render(r)
    r.html {
      r.head {
        r.title('Wee + Ajax')
        r.javascript.src('/js/jquery-1.3.1.min.js')
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
    map '/ajax' do
      run Wee::Application.new {
        Wee::Session.new(HelloWorld.new)
      }
    end
    map '/js' do
      run Rack::File.new('.')
    end
  end
  Rack::Handler::WEBrick.run(app, :Port => 2000)
end
