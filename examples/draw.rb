$LOAD_PATH.unshift << "../lib"
require 'wee'
require 'wee/webrick'
require 'wee/utils/cache'
require 'GD'

class MainPage < Wee::Component

  def initialize
    @points = []
    session.register_object_for_backtracking(@points)
  end

  def create_image(points)
    im = GD::Image.newTrueColor(200,200) 

    white = GD::Image.trueColor(255,255,255)
    black = GD::Image.trueColor(0,0,0)
    red = GD::Image.trueColor(255,0,0)

    im.transparent(white)
    im.filledRectangle(0,0,199,199,white)
    im.rectangle(0,0,199,199,black)

    points.each do |x,y|
      im.filledRectangle(x,y,x+10,y+10, red)
    end

    im.pngStr
  end

  def clear
    @points.clear
  end

  def process_request(context)
    query = context.request.unparsed_uri.split('?').last
    @x, @y = query.split(",").map {|i| i.to_i} if query
    super
  end

  # TODO: move the above into method point (we need the current context,
  # Session.current_context)
  def draw_point
    @points << [@x, @y]
  end

  def render
    r.page.title("Draw Test").with do 

      ctx = r.context.context
      img_id = ctx.handler_registry.handler_id_for_resource(
        Wee::ResourceHandler.new(create_image(@points), 'image/png'))

      img_url = ctx.application.gen_resource_url(ctx.session_id, ctx.page_id, img_id)

      r.anchor.action(:draw_point).with {
        r.image.src(img_url).ismap("")
      }

      r.break
      r.anchor.action(:clear).with('Clear')
    end 
  end

end

class MySession < Wee::Session
  def initialize
    super do
      self.root_component = MainPage.new
      self.page_store = Wee::Utils::LRUCache.new(10) # backtrack up to 10 pages
    end
  end
end

class MyApplication < Wee::Application
  def shutdown
  end
end

if __FILE__ == $0
  raise "this example does not work with the current version of Wee"
  Wee::Application.new {|app|
    app.name = 'Counter'
    app.path = '/app'
    app.session_class = MySession
    app.session_store = Wee::Utils::LRUCache.new(1000) # handle up to 1000 sessions
    app.dumpfile = ''
  }.start
end
