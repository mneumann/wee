$LOAD_PATH.unshift '../lib'
require 'wee'
require 'wee/utils/cache'
require 'wee/adaptors/webrick'
require 'utils/webrick_background'
require 'utils/memory_plotter'
require 'utils/cross'

require 'rubygems'
require 'web/unit'   # require narf-lib

require 'components/messagebox'
require 'components/calltest'
require 'components/page'


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

spid = Wee::WEBrickAdaptor.register('/app' => app).start(:Logger => DummyLog.new, :AccessLog => []).server_pid
m = MemoryPlotter.new(2, spid).run
at_exit { m.exit }

$URLBASE = 'http://localhost:2000'

class StressSession
  def initialize
    @r = Web::Unit::Response.get('/app').redirect.redirect
  end

  def step
    %w(OK Cancel).each {|b|
      @r = @r.click('show').redirect.submit('OK').redirect.submit(b).redirect
    }
    (%w(OK Cancel) ** %w(OK Cancel)).each { |b1, b2|
      @r = @r.click('show').redirect.submit('Cancel').redirect.submit(b1).redirect.submit(b2).redirect
    }
  end
end

sessions = (1..10).map { StressSession.new }
loop do
  sessions.each {|s| s.step}
  puts "--------------------------------------------------------"
end
