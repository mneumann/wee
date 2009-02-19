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

require 'wee/html_writer'
require 'wee/html_brushes'
require 'wee/html_canvas'

require 'wee/components/messagebox'
require 'wee/components/form_decoration'
require 'wee/components/page_decoration'

Wee::DefaultRenderer = Wee::HtmlCanvas

def Wee.run(component_class, mount_path='/', port=2000)
  require 'rack/handler/webrick'
  app = Rack::Builder.app do
    map mount_path do
      run Wee::Application.new { Wee::Session.new(component_class.new) }
    end
  end
  Rack::Handler::WEBrick.run(app, :Port => port)
end
