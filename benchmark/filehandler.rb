require 'webrick'
File.open('filehandler.pid', 'w+') {|f| f.puts($$.to_s) }
server = WEBrick::HTTPServer.new(:Port => 2000)
server.mount("/", WEBrick::HTTPServlet::FileHandler, '.')
trap("INT") { server.shutdown }
server.start
