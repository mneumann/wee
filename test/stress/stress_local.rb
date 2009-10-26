$LOAD_PATH.unshift "../../lib"
require 'rubygems'
require 'wee'

class HelloWorld < Wee::Component

  class Called2 < Wee::Component
    def render(r)
      r.anchor.callback { answer }.with('back')
    end
  end

  class Called1 < Wee::Component
    def render(r)
      r.anchor.callback { callcc Called2.new; answer }.with('back')
    end
  end

  def initialize
    add_decoration(Wee::PageDecoration.new("Hello World"))
    @counter = 0
  end

  def render(r)
    r.h1 "Hello World from Wee!"
    r.anchor.callback { callcc Called1.new }.with(@counter.to_s)
  end
end

class StressTest
  def initialize
    @app = Wee::Application.new {
      Wee::Session.new(HelloWorld.new, Wee::Session::ThreadSerializer.new)
    }
  end

  def request(uri)
    env = Rack::MockRequest.env_for(uri)
    resp = @app.call(env)
    if resp.first == 302
      request(resp[1]["Location"])
    else
      resp.last.body.join
    end
  end

  def run(n=10_000, verbose=false)
    next_uri = '/'

    n.times do
      p next_uri if verbose
      body = request(next_uri)

      if body =~ /href="([^"]*)"/
        next_uri = $1
      else
        raise
      end
    end
  end
end

if __FILE__ == $0
  if ARGV.size < 2 or ARGV.size > 3
    puts %{USAGE: #$0 num_threads num_iters ["verbose"]}
    exit 1
  end

  num_threads, num_iters, verbose = Integer(ARGV[0]), Integer(ARGV[1]), ARGV[2] == "verbose"

  if verbose
    $LOAD_PATH.unshift '.'
    require 'plotter'
    MemoryPlotter.new(5, Process.pid).run
    ObjectPlotter.new(5, Object, Array, String, Hash, Bignum).run
    ObjectPlotter.new(5, Thread, Continuation, Proc).run
  end

  app = StressTest.new
  (1..num_threads).map {
    Thread.new { app.run(num_iters, verbose) }
  }.each {|th| th.join}

  STDIN.readline if verbose
end
