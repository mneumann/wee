require 'webrick'
class Wee::Application
  def start(hash=nil)
    hash = {:Port => 2000}.update(hash||{})
    server = WEBrick::HTTPServer.new(hash)
    server.mount_proc(hash[:mount_path] || self.path) {|req, res| self.handle_request(req, res)}
    trap("INT") { 
      trap("INT", "IGNORE")
      self.shutdown
      server.shutdown
      exit
    }
    server.start
  end
end
