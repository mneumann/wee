require 'rubygems'
require 'wee'
require 'wee/adaptors/webrick' 
require 'wee/utils'

class AjaxTest < Wee::Component

  def render
    r.html {
      r.head {
        r.title("Ajax+Wee")
        r.javascript.src('/js/ajax.js')
      }
      r.body {
        r.h1 "Hello World from Wee!"
        r.anchor.id('blah').onclick_update('blah') { do_live_update }.with('Halllllllooooo')
      }
    }
  end

  def render_live_update
    r.text "Live-updates works! This is no. #{ @live_updates }"
  end

  def do_live_update
    # generate a response
    response = Wee::GenericResponse.new('text/plain', '')

    # get the current context we are in
    context = session.current_context

    # a rendering context is needed to use 'r' (if you want, you can
    # simply omit this and just return the response with some html/xml filled
    # in.
    rendering_context = Wee::RenderingContext.new(context.request, 
      context.response, session.current_callbacks, 
      Wee::HtmlWriter.new(response.content))

    with_renderer_for(rendering_context) do 
      # call your own render method for the live-update
      render_live_update
    end

    send_response(response)
  end
end

Wee::WEBrickAdaptor.
  register('/app' => Wee::Utils.app_for(AjaxTest)).
  mount('/js', WEBrick::HTTPServlet::FileHandler, '.').
  start 
