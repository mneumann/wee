require 'webrick'

# Example of usage: 
#
#   require 'wee/adaptors/webrick'
#   s = WEBrick::HTTPServer.new(:Port => 2000) 
#   s.mount '/app', Wee::WEBrickAdaptor, application
#
#   trap("INT") { s.shutdown; exit }
#   s.start
#
# Or when using the convenience methods:
#
#   require 'wee/adaptors/webrick'
#   Wee::WEBrickAdaptor.
#     register('/app', application).
#     register('/cnt', application2).
#     start(2000)
#

class Wee::WEBrickAdaptor < WEBrick::HTTPServlet::AbstractServlet

  # Convenience method
  def self.start(port=2000)
    server = WEBrick::HTTPServer.new(:Port => port)
    trap("INT") { server.shutdown }

    @apps.each do |path, app|
      server.mount(path, self, app)
    end

    server.start
  end

  # Convenience method
  def self.register(path, application)
    @apps ||= []
    @apps << [path, application]
    self
  end

  def initialize(server, application)
    super(server)
    @application = application
  end

  def handle_request(req, res)
    context = Wee::Context.new(Wee::Request.new(req.path, req.header, req.query))
    @application.handle_request(context)
    res.status = context.response.status
    res.body = context.response.content
    context.response.header.each { |k,v| res.header[k] = v }
  end

  alias do_GET handle_request
  alias do_POST handle_request
end
