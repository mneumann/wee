$LOAD_PATH.unshift '../lib'
require 'wee'
require 'wee/utils'
require 'wee/adaptors/webrick'
require 'utils/webrick_background'
require 'utils/memory_plotter'
require 'utils/object_plotter'
require 'utils/cross'

require 'rubygems'
require 'mechanize'   # requires my mechanize gem

require 'components/calltest'

# for stressing continuations use this instead
#require 'components/calltest-cont'
#require 'wee/continuation'

require 'components/page'

NUM_SESSIONS = 100

class DummyLog < WEBrick::BasicLog
  def initialize() super(self) end
  def <<(*args) end
end

class MySession < Wee::Session
  def initialize
    super do
      self.root_component = Page.new(CallTest.new)
      self.page_store = Wee::Utils::LRUCache.new(10) # backtrack up to 10 pages
    end
  end
end

app = Wee::Application.new {|app|
  app.default_request_handler { MySession.new }
  app.id_generator = Wee::SimpleIdGenerator.new(rand(1_000_000))
}

Wee::WEBrickAdaptor.register('/app' => app).start(:Logger => DummyLog.new, :AccessLog => [])

MemoryPlotter.new(5, $$).run
ObjectPlotter.new(5, Object, Array, String, Bignum).run
ObjectPlotter.new(5, Thread, Continuation, Proc).run

class StressSession
  def initialize
    @agent = WWW::Mechanize.new {|a| 
      #a.log = Logger.new(STDERR)
      a.max_history = 2
    }
    @agent.get('http://localhost:2000/app')
  end

  def click(val)
    link = @agent.page.links.find {|l| l.node.text == val}
    @agent.click(link)
  end

  def submit(val)
    form = @agent.page.forms.first
    button = form.buttons.find {|b| b.value == val}
    @agent.submit(form, button)
  end

  def step
    %w(OK Cancel).each {|b|
      click('show')
      submit('OK')
      submit(b)
    }
    (%w(OK Cancel) ** %w(OK Cancel)).each { |b1, b2|
      click('show')
      submit('Cancel')
      submit(b1)
      submit(b2)
    }
  end
end

sessions = (1..NUM_SESSIONS).map { StressSession.new }
loop do
  sessions.each {|s| s.step }
end
