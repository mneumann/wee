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
#     request_class(Wee::Request).      # this is the default!
#     register('/app' => application).
#     register('/cnt' => application2).
#     mount('/', WEBrick::HTTPServlet::FileHandler, '.').
#     start(:Port => 2000)
#

Socket.do_not_reverse_lookup = true

class Wee::WEBrickAdaptor < WEBrick::HTTPServlet::AbstractServlet

  # Convenience method
  def self.start(options={})
    server = WEBrick::HTTPServer.new({:Port => 2000}.update(options))
    trap("INT") { server.shutdown }

    (@apps||[]).each do |path, app, request_class|
      server.mount(path, self, path, app, request_class)
    end

    (@mounts||[]).each do |args, block|
      server.mount(*args, &block)
    end

    yield server if block_given?

    server.start
    server
  end

  # Sets the used request_class for all following calls to #register

  def self.request_class(request_class)
    @request_class = request_class
    self
  end

  # Convenience method
  def self.register(hash)
    @apps ||= []
    hash.each do |path, application|
      @apps << [path, application, @request_class]
    end
    self
  end

  # Convenience method
  def self.mount(*args, &block)
    @mounts ||= []
    @mounts << [args, block]
    self
  end

  def initialize(server, mount_path, application, request_class=Wee::Request)
    super(server)
    @mount_path = mount_path
    @application = application
    @request_class = request_class || Wee::Request
  end

  def handle_request(req, res)
    context = Wee::Context.new(@request_class.new(@mount_path, req.path, req.header, req.query, req.cookies))
    @application.handle_request(context)
    res.status = context.response.status
    res.body = context.response.content
    context.response.header.each { |k,v| res.header[k] = v }
    if context.response.cookies?
      context.response.cookies.each {|c| res.cookies << c } 
    end
  end

  alias do_GET handle_request
  alias do_POST handle_request
end
