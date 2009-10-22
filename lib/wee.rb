module Wee
  Version = "2.0.0"
end

require 'rack'

require 'wee/state'
require 'wee/callback'

require 'wee/presenter'
require 'wee/decoration'
require 'wee/component'

require 'wee/application'
require 'wee/request'
require 'wee/response'
require 'wee/session'

require 'wee/html_document'
require 'wee/html_brushes'
require 'wee/html_canvas'

if RUBY_VERSION >= "1.9"
  begin
    require 'continuation'
  rescue LoadError
  end
end

Wee::DefaultRenderer = Wee::HtmlCanvas

def Wee.run(component_class=nil, mount_path='/', port=2000, &block)
  raise ArgumentError if component_class and block

  require 'rack/handler/webrick'
  app = Rack::Builder.app do
    map mount_path do
      if block
        run Wee::Application.new(&block)
      else
        run Wee::Application.new { Wee::Session.new(component_class.new) }
      end
    end
  end
  Rack::Handler::WEBrick.run(app, :Port => port)
end

#
# Like Wee.run, but for use with continuations.
#
def Wee.runcc(component_class, *args)
  Wee.run(nil, *args) {
    Wee::Session.new(component_class.new, Wee::Session::ThreadSerializer.new)
  }
end
