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
  attr_reader :context  # the current Wee::RenderingContext
  attr_reader :document
  attr_accessor :current_component

  def initialize(rendering_context)
    @context = rendering_context
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
    obj.render_chain(@context)
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

class Brush
  attr_accessor :parent, :canvas

  def with(*args, &block)
    raise "either args or block, but not both" if block and not args.empty?

    @canvas.nest(&block) if block
    @closed = true
  end

  def close
    with unless @closed
  end
end

class Brush::GenericTextBrush < Brush
  def initialize(text)
    @text = text
  end

  def with
    doc = @canvas.document
    doc << @text
    super
    nil
  end
end

class Brush::GenericEncodedTextBrush < Brush
  def initialize(text)
    @text = text
  end

  def with
    doc = @canvas.document
    doc.encode_text(@text)
    super
    nil
  end
end

class Brush::GenericTagBrush < Brush
  def initialize(tag)
    @tag = tag
    @attributes = Hash.new
  end

  def id(x)
    @attributes["id"] = x
    self
  end

  def method_missing(m, arg)
    @attributes[m.to_s] = arg.to_s
    self
  end

  def with(text=nil, &block)
    doc = @canvas.document
    doc.start_tag(@tag, @attributes)
    if text
      doc.text(text)
      super(text, &block)
    else
      super(&block)
    end
    doc.end_tag(@tag)
    nil
  end
end

class Brush::TableTag < Brush::GenericTagBrush
  def initialize
    super('table')
  end
end  

class Brush::TableRowTag < Brush::GenericTagBrush
  def initialize
    super('tr')
  end

  def align_top
    @attributes['align'] = 'top'
    self
  end

  def columns(*cols)
    with {
      cols.each {|col| @canvas.table_data(col) }
    } 
  end

  def headings(*headers)
    with {
      headers.each {|head| @canvas.table_heading(head) }
    } 
  end

  def spanning_column(str, colspan)
    with {
      @canvas.table_data.col_span(colspan).with(str)
    }
  end

  def spacer
    with {
      @canvas.table_data { @canvas.space }
    }
  end
end


class Brush::InputTag < Brush::GenericTagBrush
  def initialize
    super('input')
  end

  %w(type name value size maxlength checked src).each do |meth|
    eval %[
      def #{ meth }(arg)
        @attributes['#{ meth }'] = arg
        self
      end
    ]
  end

  def with
    super
  end
end

module Brush::AssignMixin
  def assign(act, obj=nil)
    ctx = @canvas.context.context
    obj ||= @canvas.current_component

    name(ctx.callback_registry.register(Wee::MethodCallback[obj, act], :input))
  end
end

class Brush::TextAreaTag < Brush::GenericTagBrush
  include Brush::AssignMixin

  def initialize
    super('textarea')
  end

  %w(name rows cols tabindex accesskey onfocus onblur onselect onchange).each do |meth|
    eval %[
      def #{ meth }(arg)
        @attributes['#{ meth }'] = arg
        self
      end
    ]
  end

  def disabled
    @attributes['disabled'] = nil 
    self
  end

  def readonly
    @attributes['readonly'] = nil 
    self
  end

  def with(*args, &block)
    super
  end
end

class Brush::SelectListTag < Brush::GenericTagBrush
  include Brush::AssignMixin

  def initialize(items)
    super('select')
    @items = items
    @default = nil
    @labels = @items.collect { |i| i.to_s }
  end

  %w(default items labels).each do |meth|
    eval %[
    def #{ meth }(arg)
      @#{ meth } = arg
      self
    end
    ]
  end

  def with(*args, &block)
    super
    @items.each_index do |i|
      @canvas.option.value(@items[i]).selected(@default).with(@labels[i])
    end
  end
end

class Brush::SelectOptionTag < Brush::GenericTagBrush

  def initialize
    super('option')
  end

  def selected(*args)
    if args.size == 0
      @attributes['selected'] = 'selected'
    else
      @attributes['selected'] = 'selected' if args.first.to_s == @attributes['value']
    end
    self
  end
end

class Brush::TextInputTag < Brush::InputTag
  include Brush::AssignMixin

  def initialize
    super
    type('text')
  end

  def attr(attr_name)
    assign(attr_name.to_s + "=")
    value(@canvas.current_component.send(attr_name))
    self
  end
end

class Brush::SubmitButtonTag < Brush::InputTag
  def initialize
    super
    type('submit')
  end

  # TODO: action for another object
  def action(act, *args)
    ctx = @canvas.context.context
    obj = @canvas.current_component

    name(ctx.callback_registry.register(Wee::MethodCallback[obj, act, *args], :action))
  end
end

class Brush::TableDataTag < Brush::GenericTagBrush
  def initialize
    super('td')
  end

  def align_top
    @attributes['align'] = 'top'
    self
  end
end

class Brush::TableHeaderTag < Brush::GenericTagBrush
  def initialize
    super('th')
  end
end

module Brush::ActionMixin
  # TODO: action for another object
  def action(act, *args)
    ctx = @canvas.context.context
    obj = @canvas.current_component
    href = ctx.application.gen_handler_url(ctx.session_id, ctx.page_id, 
           act ? ctx.callback_registry.register(Wee::MethodCallback[obj, act, *args], :action) : '')
    __action(href)
  end
end

class Brush::FormTag < Brush::GenericTagBrush
  include Brush::ActionMixin

  def initialize
    super('form')
    @attributes['method'] = 'POST'
  end

  def __action(href)
    @attributes['action'] = href 
    self
  end

  def with(*args, &block)
    action(nil) unless @attributes.has_key?('action')
    super
  end
end

class Brush::AnchorTag < Brush::GenericTagBrush
  include Brush::ActionMixin

  def initialize
    super('a')
  end

  def url(href)
    @attributes['href'] = href 
    self
  end

  alias __action url 
end


class Brush::Page < Brush
  def title(str)
    @title = str
    self
  end

  def with(text=nil, &block)
    doc = @canvas.document
    doc.start_tag("html")

    if @title
      doc.start_tag("head")
      doc.start_tag("title")
      doc.text(@title)
      doc.end_tag("title")
      doc.end_tag("head")
    end

    doc.start_tag("body")

    if text
      doc.text(text)
      super(text, &block)
    else
      super(&block)
    end

    doc.end_tag("body")
    doc.end_tag("html")
    nil
  end
end

end # module Wee

if __FILE__ == $0
  require 'html_writer'

  doc = Wee::HtmlWriter.new('')
  c = Wee::HtmlCanvas.new(nil, doc)
  c.form.url("foo").with {
    c.table {
      c.table_row.id("myrow").with {
        c.table_data.align_top.with("Hello world")
      }
    }
    c.space
  }
  puts doc.port
end
