module Wee

class Canvas
  def initialize
    @parent_brush = nil
    @current_brush = nil
  end

  def close
    @current_brush.close if @current_brush
    @current_brush = nil
  end

  def set_brush(brush)
    # tell previous brush to finish
    @current_brush.close if @current_brush

    brush.parent = @parent_brush
    brush.canvas = self
    @current_brush = brush

    return brush
  end

  def nest(&block)
    @parent_brush = @current_brush
    @current_brush = nil
    block.call
    @current_brush.close if @current_brush
    @parent_brush = @parent_brush.parent 
  end
end

class HtmlCanvas < Canvas
  attr_reader :rendering_context  # the current Wee::RenderingContext
  attr_reader :document
  attr_accessor :current_component

  def self.generic_tag(*attrs)
    attrs.each { |a|
      class_eval " 
        def #{ a }(*args, &block)
          handle(Brush::GenericTagBrush.new('#{ a }'), *args, &block)
        end
      "
    }
  end

  def self.generic_single_tag(*attrs)
    attrs.each { |a|
      class_eval " 
        def #{ a }(*args, &block)
          handle(Brush::GenericSingleTagBrush.new('#{ a }'), *args, &block)
        end
      "
    }
  end

  def initialize(rendering_context)
    super()
    @rendering_context = rendering_context
    @document = rendering_context.document
  end

  generic_tag :html, :head, :body, :title, :style, :h1, :h2, :h3, :h4, :h5, :div
  generic_single_tag :link

  def url_for_callback(callback)
    req = self.rendering_context.request
    url = req.build_url(req.request_handler_id, req.page_id, register_callback(:action, callback))
    return url
  end

  def register_callback(type, callback)
    self.rendering_context.callbacks.register_for(self.current_component, type, callback)
  end

  def table(*args, &block)
    handle(Brush::TableTag.new, *args, &block)
  end

  def table_row(*args, &block)
    handle(Brush::TableRowTag.new, *args, &block)
  end

  def table_data(*args, &block)
    handle(Brush::TableDataTag.new, *args, &block)
  end

  def table_header(*args, &block)
    handle(Brush::TableHeaderTag.new, *args, &block)
  end

  def form(*args, &block)
    handle(Brush::FormTag.new, *args, &block)
  end 

  def input(*args, &block)
    handle(Brush::InputTag.new, *args, &block)
  end

  def text_input(*args, &block)
    handle(Brush::TextInputTag.new, *args, &block)
  end

  def text_area(*args, &block)
    handle(Brush::TextAreaTag.new, *args, &block)
  end

  def option(*args, &block)
    handle(Brush::SelectOptionTag.new, *args, &block)
  end

  def select_list(items)
    handle(Brush::SelectListTag.new(items))
  end

  def submit_button(*args, &block)
    handle(Brush::SubmitButtonTag.new, *args, &block)
  end

  def image_button(*args, &block)
    handle(Wee::Brush::ImageButtonTag.new, *args, &block)
  end

  def file_upload(*args, &block)
    handle(Wee::Brush::FileUploadTag.new, *args, &block)
  end

  def page(*args, &block)
    handle(Brush::Page.new, *args, &block)
  end 

  def anchor(*args, &block)
    handle(Brush::AnchorTag.new, *args, &block)
  end 

  def space(n=1)
    set_brush(Brush::GenericTextBrush.new("&nbsp;"*n))
  end

  def bold(*args, &block)
    handle(Brush::GenericTagBrush.new("b"), *args, &block)
  end

  def paragraph
    set_brush(Brush::GenericSingleTagBrush.new("p"))
  end

  def break
    set_brush(Brush::GenericSingleTagBrush.new("br"))
  end

  def image
    handle(Brush::ImageTag.new)
  end

  def link_css(url)
    link.type('text/css').rel('stylesheet').href(url)
  end

  def text(str)
    set_brush(Brush::GenericTextBrush.new(str))
  end
  alias << text

  def encode_text(str)
    set_brush(Brush::GenericEncodedTextBrush.new(str))
  end

  def render(obj)
    self.close
    obj.do_render_chain(@rendering_context)
    nil
  end

  private

  def handle(brush, *args, &block)
    set_brush(brush)
    if not args.empty? or block
      brush.with(*args, &block) 
    else
      brush
    end
  end
end

end # module Wee
