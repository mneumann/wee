$LOAD_PATH.unshift << "../lib"
require 'wee'
require 'wee/webrick'
require 'wee/utils/cache'


class Counter < Wee::Component
  def initialize(cnt)
    super()
    @cnt = cnt 
    session.register_object_for_backtracking(self)
  end

  def dec
    @cnt -= 1
  end

  def inc
    @cnt += 1
  end

  def render
    r.anchor.action(:dec).with("--")
    r.space; r.text(@cnt.to_s); r.space 
    r.anchor.action(:inc).with("++")
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
    end
  end
end

if __FILE__ == $0
  DUMP = 'dump'

  if File.exists?(DUMP)
    Wee::Application.load_from_disk(DUMP)
  else
    Wee::Application.new {|app|
      app.name = 'Counter'
      app.path = '/app'
      app.session_class = MySession
      app.session_store = Wee::Utils::LRUCache.new(1000) # handle up to 1000 sessions
      app.dumpfile = DUMP
    }
  end.start
end
