require 'webrick'
require 'timeout'

class WEBrick::HTTPServer
  alias old_start start

  def start
    raise "already started" if @__started
    raise unless @config[:StartCallback].nil?
    @config[:StartCallback] = proc { @__started = true }

    Thread.new {
      old_start
      @__started = false
    }

    Timeout.timeout(5) {
      nil until @__started # wait until the server is ready
    }
  end

  alias old_shutdown shutdown

  def shutdown
    raise unless @__started
    Timeout.timeout(5) {
      old_shutdown
      nil while @__started # wait until the server is down
    }
  end
end
