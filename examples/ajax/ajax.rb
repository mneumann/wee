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
        r.anchor.id('tag').onclick_update('tag', :update).with('Halllllllooooo')
      }
    }
  end

  def update
    send_render_response {
      r.text "Live-updates works! This is no. #{ @live_updates = (@live_updates || 0) + 1 }"
    }
  end
end

Wee::WEBrickAdaptor.
  register('/app' => Wee::Utils.app_for(AjaxTest)).
  mount('/js', WEBrick::HTTPServlet::FileHandler, '.').
  start 
