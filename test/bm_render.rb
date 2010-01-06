#
# Render Wee::HelloWorld n-times
#

$LOAD_PATH.unshift "./lib"
require 'rubygems'
require 'wee'
require 'rack'

class Rack::Request
  def put?; get? end
end

class Wee::HtmlWriter
  def join
    @port
  end
end

root_component = Wee::HelloWorld.new
Integer(ARGV[0] || raise).times do
  r = Wee::Renderer.new
  r.request   = Wee::Request.new({'REQUEST_METHOD' => 'GET', 'SCRIPT_NAME' => 'blah', 'PATH_INFO' => 'blubb',
  'QUERY_STRING' => '_p=blah&_s=session'})
  r.document  = Wee::HtmlDocument.new
  r.callbacks = Wee::Callbacks.new

  begin
    root_component.decoration.render!(r)
  ensure
    r.close
  end
  Wee::GenericResponse.new(r.document.join)
end
