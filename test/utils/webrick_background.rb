require 'webrick'
require 'timeout'

class WEBrick::HTTPServer
  alias old_start start

  def start
    raise "already started" if @__server_pid or @__started

    raise unless @config[:StartCallback].nil?
    @config[:StartCallback] = proc { Process.kill('USR1', Process.ppid) }

    trap('USR1') { @__started = true }
    trap('INT') { shutdown; trap('INT', 'DEFAULT'); Process.kill('INT', Process.pid) }
    at_exit { shutdown if @__started }
    @__server_pid = fork {
      trap('INT', 'IGNORE')
      trap('USR1') { p "going to shutdown"; old_shutdown }
      old_start
      exit
    }

    Timeout.timeout(5) {
      nil until @__started # wait until the server is ready
    }
  end

  alias old_shutdown shutdown

  def shutdown
    raise if @__server_pid.nil? or not @__started
    Process.kill('USR1', @__server_pid)
    Process.wait(@__server_pid)
    raise $?.to_s unless $?.success?
    trap('USR1', 'DEFAULT')
    trap('INT', 'DEFAULT')
    @__server_pid = nil
    @__started = false
  end

  def server_pid
    @__server_pid
  end

end
