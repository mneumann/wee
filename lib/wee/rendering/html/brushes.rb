module Wee

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

module Brush::CallbackMixin
  private 

  def register_callback(type, &block)
    raise ArgumentError, "no callback block given" if block.nil?
    @canvas.rendering_context.callbacks.register_for(@canvas.current_component, type, &block)
  end
end

module Brush::InputCallbackMixin
  include Brush::CallbackMixin

  public

  def callback(&block)
    name(register_callback(:input, &block))
  end
end

module Brush::ActionCallbackMixin
  include Brush::CallbackMixin

  public

  def callback(&block)
    name(register_callback(:action, &block))
  end
end

# The callback id is listed in the URL (not as a form-data field)
module Brush::ActionURLCallbackMixin
  include Brush::CallbackMixin

  public

  def callback(&block)
    req = @canvas.rendering_context.request
    url = req.build_url(req.session_id, req.page_id, register_callback(:action, &block))
    __set_url(url)
  end
end

class Brush::TextAreaTag < Brush::GenericTagBrush
  include Brush::InputCallbackMixin

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
  include Brush::InputCallbackMixin

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
  include Brush::InputCallbackMixin

  def initialize
    super
    type('text')
  end
end

class Brush::SubmitButtonTag < Brush::InputTag
  include Brush::ActionCallbackMixin

  def initialize
    super
    type('submit')
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


class Brush::FormTag < Brush::GenericTagBrush
  include Brush::ActionURLCallbackMixin

  def initialize
    super('form')
    @attributes['method'] = 'POST'
  end

  def action(href)
    @attributes['action'] = href 
    self
  end

  alias __set_url action

  def with(*args, &block)

    # If no action or callback was specified, use a dummy callback.  This is
    # required that other form-elements are handled correctly. 
    callback{} unless @attributes.has_key?('action')

    super
  end
end

class Brush::AnchorTag < Brush::GenericTagBrush
  include Brush::ActionURLCallbackMixin

  def initialize
    super('a')
  end

  def url(href)
    @attributes['href'] = href 
    self
  end
  alias href url

  alias __set_url url
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
