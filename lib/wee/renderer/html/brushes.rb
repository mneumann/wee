module Wee

class Brush
  attr_accessor :parent, :canvas

  def initialize
    @parent = @canvas = @closed = nil
  end

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
    super()
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
    super()
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
    super()
    @tag = tag
    @attributes = Hash.new
  end

  def type(t)
    @attributes["type"] = t
    self
  end

  def css_class(c)
    @attributes["class"] = c
    self
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

  def columns(*cols, &block)
    with {
      cols.each {|col|
        @canvas.table_data.with {
          if block
            block.call(col)
          else
            @canvas.text(col)
          end
        }
      }
    } 
  end

  def headings(*headers, &block)
    with {
      headers.each {|header|
        @canvas.table_header.with {
          if block
            block.call(header)
          else
            @canvas.text(header)
          end
        }
      }
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

module Brush::InputCallbackMixin
  public

  def callback(symbol=nil, &block)
    raise ArgumentError if symbol and block
    block = @canvas.current_component.method(symbol) unless block
    name(@canvas.register_callback(:input, &block))
  end
end

module Brush::ActionCallbackMixin
  public

  def callback(symbol=nil, &block)
    raise ArgumentError if symbol and block
    block = @canvas.current_component.method(symbol) unless block
    name(@canvas.register_callback(:action, &block))
  end
end

# The callback id is listed in the URL (not as a form-data field)
module Brush::ActionURLCallbackMixin
  public

  def callback(symbol=nil, &block)
    __set_url(@canvas.url_for_callback(symbol, &block))
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

class Brush::SelectOptionTag < Brush::GenericTagBrush
  def initialize
    super('option')
  end

  def selected(bool=true)
    if bool
      @attributes['selected'] = nil
    else
      @attributes.delete('selected')
    end
    self
  end
end

class Brush::SelectListTag < Brush::GenericTagBrush
  include Brush::InputCallbackMixin

  def initialize(items)
    super('select')
    @items = items
  end

  %w(selected items labels).each do |meth|
    eval %[
    def #{ meth }(arg)
      @#{ meth } = arg
      self
    end
    ]
  end

  def multiple
    @multiple = true
    @attributes['multiple'] = nil
    self
  end

  alias __old_callback callback
  private :__old_callback
  def callback(symbol=nil, &block)
    raise ArgumentError if symbol and block
    block = @canvas.current_component.method(symbol) unless block

    @callback = block
    self
  end

  def with
    @labels ||= @items.collect { |i| i.to_s }
    @selected ||= Array.new

    if @callback
      __old_callback {|input|
        choosen = input.list.map {|idx| 
          idx = Integer(idx)
          raise "invalid index in select list" if idx < 0 or idx > @items.size
          @items[idx]
        }
        raise "choosen more than one element from a non-multiple select list" if not @multiple and choosen.size > 1
        @callback.call(choosen)
      }
    end

    super do
      @items.each_index do |i|
        @canvas.option.value(i).selected(@selected.include?(@items[i])).with(@labels[i])
      end
      @canvas.text("")
    end
  end
end

class Brush::TextInputTag < Brush::InputTag
  include Brush::InputCallbackMixin

  def initialize
    super
    type('text')
  end
end

class Wee::Brush::FileUploadTag < Wee::Brush::InputTag
  include Brush::InputCallbackMixin

  def initialize
    super
    type('file')
  end
end



class Brush::SubmitButtonTag < Brush::InputTag
  include Brush::ActionCallbackMixin

  def initialize
    super
    type('submit')
  end
end

# NOTE: The form-fields returned by a image-button-tag is browser-specific.
# Most browsers do not send the "name" key together with the value specified by
# "value", only "name.x" and "name.y". This conforms to the standard. But
# Firefox also sends "name"="value". This is why I raise an exception from the
# #value method. Note that it's neccessary to parse the passed form-fields and
# generate a "name" fields in the request, to make this image-button work. 

class Wee::Brush::ImageButtonTag < Wee::Brush::InputTag
  include Brush::ActionCallbackMixin

  def initialize
    super
    type('image')
  end

  def value(v)
    raise "specified value will not be used in the request"
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

  def enctype(typ)
    @attributes['enctype'] = typ
    self
  end

  alias __set_url action

  def with(*args, &block)
    # If no action was specified, use a dummy one.
    unless @attributes.has_key?('action')
      req = @canvas.rendering_context.request
      @attributes['action'] = req.build_url(req.request_handler_id, req.page_id) 
    end
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
