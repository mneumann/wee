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

  def initialize(rendering_context)
    super()
    @rendering_context = rendering_context
    @document = rendering_context.document
  end

  def bold(*args, &block)
    handle(Brush::GenericTagBrush.new("b"), *args, &block)
  end

  def method_missing(id, *args, &block)
    handle(Brush::GenericTagBrush.new(id.to_s), *args, &block)
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

  def page(*args, &block)
    handle(Brush::Page.new, *args, &block)
  end 

  def anchor(*args, &block)
    handle(Brush::AnchorTag.new, *args, &block)
  end 

  def space(n=1)
    set_brush(Brush::GenericTextBrush.new("&nbsp;"*n))
  end

  def break
    set_brush(Brush::GenericTagBrush.new("br"))
  end

  def image
    set_brush(Brush::GenericTagBrush.new("img"))
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
    obj.render_chain(@rendering_context)
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
