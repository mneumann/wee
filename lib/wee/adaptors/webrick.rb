require 'webrick'
class Wee::Application
  def start(hash=nil)
    hash = {:Port => 2000}.update(hash||{})
    server = WEBrick::HTTPServer.new(hash)
    server.mount_proc(hash[:mount_path]) {|req, res| 
      context = Wee::Context.new(Wee::Request.new(req.path, req.header, req.query))
      self.handle_request(context)

      res.status = context.response.status
      res.body = context.response.content
      context.response.header.each { |k,v| res.header[k] = v }
    }
    trap("INT") { 
      trap("INT", "IGNORE")
      server.shutdown
      exit
    }
    server.start
  end
end
