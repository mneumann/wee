$LOAD_PATH.unshift << "../lib"
require 'wee'

class Counter < Wee::Component
  def initialize(cnt)
    super()
    @cnt = cnt 
  end

  def backtrack_state(snap)
    super
    snap.add(self)
  end

  def dec
    @cnt -= 1
  end

  def inc
    @cnt += 1
  end

  def render
    r.anchor.callback(:dec).with("--")
    r.space; r.text(@cnt.to_s); r.space 
    r.anchor.callback(:inc).with("++")
  end
end

class MainPage < Wee::Component
  def initialize
    super
    @counters = (1..10).map {|i| Counter.new(i)}
    children.push(*@counters)
  end

  def render
    r.page.title("Counter Test").with do 
      @counters.each { |cnt| r.render(cnt); r.break  }
    end
  end
end

class MySession < Wee::Session
  def initialize
    super do
      self.root_component = MainPage.new
      self.page_store = Wee::Utils::LRUCache.new(10) # backtrack up to 10 pages
      self.expire_after = 60
    end
  end
end

if __FILE__ == $0
  require 'wee/utils'
  require 'wee/adaptors/webrick'
  app = Wee::Application.new {|app|
    app.default_request_handler { MySession.new }
    app.id_generator = Wee::SimpleIdGenerator.new(rand(1_000_000))
    app.max_request_handlers = 2
  }
  Wee::WEBrickAdaptor.register('/app' => app).start
end
