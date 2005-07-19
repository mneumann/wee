#!/usr/bin/env ruby
$LOAD_PATH.unshift << "../lib"
require 'wee'
require 'wee/examples/counter'

class MainPage < Wee::Component
  def initialize
    super
    @counters = (1..10).map {|i| Wee::Examples::Counter.new(i)}
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
    app.id_generator = Wee::SequentialIdGenerator.new(rand(1_000_000))
    app.max_request_handlers = 2
  }
  Wee::WEBrickAdaptor.register('/app' => app).start
end
