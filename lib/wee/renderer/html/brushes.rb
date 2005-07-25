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

class Brush

class GenericTextBrush < Brush
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

class GenericEncodedTextBrush < Brush
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

class GenericTagBrush < Brush

  class << self
    private

		def html_attr(attr, hash={})
      name = hash[:html_name] || attr

      case hash[:type]
      when :bool
        class_eval " 
          def #{ attr }(bool=true)
            if bool
              @attributes['#{ name }'] = nil
            else
              @attributes.delete('#{ name }')
            end
            self
          end
        "
      else
        class_eval " 
          def #{ attr }(value)
            if value == nil
              @attributes.delete('#{ name }')
            else
              @attributes['#{ name }'] = value.to_s
            end
            self
          end
        "
      end

      if hash[:aliases]
        hash[:aliases].each do |a|
          class_eval "alias #{ a } #{ attr }"
        end
      end

      if hash[:shortcuts]
        hash[:shortcuts].each_pair do |k,v|
          class_eval "
            def #{ k }() #{ attr }(#{ v.inspect }) end
          "
        end
      end
		end
  end

  private

  def html_attr(attr, value)
    if value.nil?
      @attributes.delete(attr)
    else
      @attributes[attr] = value.to_s
    end
    self
  end

  # Converts the arguments into a callable object.
  #
  def to_callback(symbol, args, block)
    raise ArgumentError if symbol and block
    if symbol.nil?
      raise ArgumentError if not args.empty?
      block
    else
      if symbol.is_a?(Symbol) or symbol.is_a?(String)
        Wee::LiteralMethodCallback.new(@canvas.current_component, symbol, *args)
      else
        raise ArgumentError if not args.empty?
        symbol
      end
    end
  end

  public

  def __input_callback(symbol=nil, *args, &block)
    name(@canvas.register_callback(:input, to_callback(symbol, args, block)))
  end

  def __action_callback(symbol=nil, *args, &block)
    name(@canvas.register_callback(:action, to_callback(symbol, args, block)))
  end

  # The callback id is listed in the URL (not as a form-data field)

  def __actionurl_callback(symbol=nil, *args, &block)
    __set_url(@canvas.url_for_callback(to_callback(symbol, args, block)))
  end

  # The callback id is listed in the URL (not as a form-data field)

  def __actionurl_named_callback(name, symbol=nil, *args, &block)
    __set_url(@canvas.url_for_named_callback(name, to_callback(symbol, args, block)))
  end

  def method_missing(id, attr)
    html_attr(id.to_s, attr)
  end

  def initialize(tag, is_single_tag=false)
    super()
    @tag, @is_single_tag = tag, is_single_tag
    @attributes = Hash.new
  end

  html_attr 'type'
  html_attr 'id'
  html_attr 'css_class', :html_name => 'class'

  def onclick_callback(symbol=nil, *args, &block)
    raise ArgumentError if symbol and block
    url = @canvas.url_for_callback(to_callback(symbol, args, block))
    onclick("javascript: document.location.href='#{ url }';")          
  end

  def onclick_update(update_id, symbol=nil, *args, &block)
    raise ArgumentError if symbol and block
    url = @canvas.url_for_callback(to_callback(symbol, args, block))
    onclick("javascript: new Ajax.Updater('#{ update_id }', '#{ url }', {method:'get'}); return false;")
  end

  def with(text=nil, &block)
    doc = @canvas.document
    if @is_single_tag
      raise ArgumentError if text or block
      doc.single_tag(@tag, @attributes) 
      @closed = true
    else
      doc.start_tag(@tag, @attributes)
      if text
        doc.text(text)
        super(text, &block)
      else
        super(&block)
      end
      doc.end_tag(@tag)
    end
    nil
  end
end

class GenericSingleTagBrush < GenericTagBrush
  def initialize(tag)
    super(tag, true)
  end
end

class ImageTag < GenericSingleTagBrush
  html_attr 'src'

  def initialize
    super('img')
  end

  def with
    super
  end
end

class JavascriptTag < GenericTagBrush
  html_attr 'src'
  html_attr 'type'

  def initialize
    super('script')
    type('text/javascript')
  end
end

class TableTag < GenericTagBrush
  def initialize
    super('table')
  end
end  

class TableRowTag < GenericTagBrush
  def initialize
    super('tr')
  end

  html_attr 'align', :shortcuts => {
    :align_top => 'top',
    :align_bottom => 'bottom'
  }

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

class InputTag < GenericSingleTagBrush
  def initialize
    super('input')
  end

  html_attr 'type'
  html_attr 'name'
  html_attr 'value'
  html_attr 'size'
  html_attr 'maxlength'
  html_attr 'src'
  html_attr 'checked',  :type => :bool
  html_attr 'disabled', :type => :bool
  html_attr 'readonly', :type => :bool

  def with
    super
  end
end

class TextAreaTag < GenericTagBrush
  def initialize
    super('textarea')
  end

  alias callback __input_callback

  html_attr 'name'
  html_attr 'rows'
  html_attr 'cols'
  html_attr 'tabindex'
  html_attr 'accesskey'
  html_attr 'onfocus'
  html_attr 'onblur'
  html_attr 'onselect'
  html_attr 'onchange'
  html_attr 'disabled', :type => :bool
  html_attr 'readonly', :type => :bool

  def value(val)
    @value = val
    self
  end

  def with(*args, &block)
    if @value
      if block or !args.empty?
        raise "please use either method 'value' or 'with'"
      else
        super(@value)
      end
    else
      super
    end
  end
end

class SelectOptionTag < GenericTagBrush
  def initialize
    super('option')
  end

  html_attr 'selected', :type => :bool
end

class SelectListTag < GenericTagBrush

  html_attr 'disabled', :type => :bool
  html_attr 'readonly', :type => :bool
  html_attr 'multiple', :type => :bool, :aliases => [:multi]

  def initialize(items)
    super('select')
    @items = items
  end

  def items(arg)
    @items = arg
    self
  end

  def selected(arg=nil, &block)
    raise if arg and block
    @selected = block || arg
    self
  end

  def labels(arg=nil, &block)
    raise if arg and block

    if block
      @labels = proc{|i| block.call(@items[i])}
    else
      @labels = arg
    end
    self
  end

  def callback(symbol=nil, *args, &block)
    @callback = to_callback(symbol, args, block)
    self
  end

  class SelectListCallback < Struct.new(:callback, :items, :is_multiple)
    def call(input)
      choosen = input.list.map {|idx| 
        idx = Integer(idx)
        raise "invalid index in select list" if idx < 0 or idx > items.size
        items[idx]
      }
      if choosen.size > 1 and not is_multiple
        raise "choosen more than one element from a non-multiple select list" 
      end
      if is_multiple
        callback.call(choosen)
      else
        callback.call(choosen.first)
      end
    end
  end

  def with
    @labels ||= @items.collect { |i| i.to_s }

    is_multiple = @attributes.has_key?('multiple')

    if @callback
      # A callback was specified. We have to wrap it inside a
      # SelectListCallback object as we want to perform some 
      # additional actions.
      __input_callback(SelectListCallback.new(@callback, @items, is_multiple))
    end

    super do
      meth = 
      if is_multiple 
        @selected ||= Array.new
        @selected.kind_of?(Proc) ? (:call) : (:include?)
      else
        @selected.kind_of?(Proc) ? (:call) : (:==)
      end

      @items.each_index {|i|
        @canvas.option.value(i).selected(@selected.send(meth, @items[i])).with(@labels[i])
      }
    end
  end
end

class HiddenInputTag < InputTag
  def initialize
    super
    type('hidden')
  end

  alias callback __input_callback
end

class PasswordInputTag < InputTag
  def initialize
    super
    type('password')
  end

  alias callback __input_callback
end

class TextInputTag < InputTag
  def initialize
    super
    type('text')
  end

  alias callback __input_callback
end

class RadioButtonTag < InputTag
  def initialize
    super
    type('radio')
  end

  class RadioGroup
    def initialize(canvas)
      @name = canvas.register_callback(:input, self)
      @callbacks = {} 
      @ids = Wee::SequentialIdGenerator.new 
    end

    def add_callback(callback)
      value = @ids.next.to_s
      @callbacks[value] = callback
      return [@name, value]
    end

    def call(value)
      if @callbacks.has_key?(value)
        cb = @callbacks[value]
        cb.call(value) if cb
      else
        raise "invalid radio button/group value"
      end
    end
  end

  def group(radio_group)
    @group = radio_group
    self
  end

  def callback(symbol=nil, *args, &block)
    @callback = to_callback(symbol, args, block)
    self
  end

  def with
    if @group
      n, v = @group.add_callback(@callback)
      name(n)
      value(v)
    end
    super
  end

end

class CheckboxTag < InputTag
  def initialize
    super
    type('checkbox')
  end
  alias callback __input_callback
end

class FileUploadTag < InputTag
  def initialize
    super
    type('file')
  end

  alias callback __input_callback
end

class SubmitButtonTag < InputTag
  def initialize
    super
    type('submit')
  end

  alias callback __action_callback
end

# NOTE: The form-fields returned by a image-button-tag is browser-specific.
# Most browsers do not send the "name" key together with the value specified by
# "value", only "name.x" and "name.y". This conforms to the standard. But
# Firefox also sends "name"="value". This is why I raise an exception from the
# #value method. Note that it's neccessary to parse the passed form-fields and
# generate a "name" fields in the request, to make this image-button work. 

class ImageButtonTag < InputTag
  def initialize
    super
    type('image')
  end

  alias callback __action_callback

  def value(v)
    raise "specified value will not be used in the request"
  end
end

class TableDataTag < GenericTagBrush
  def initialize
    super('td')
  end

  html_attr 'align', :shortcuts => {
    :align_top => 'top',
    :align_bottom => 'bottom'
  }
end

class TableHeaderTag < GenericTagBrush
  def initialize
    super('th')
  end
end

class FormTag < GenericTagBrush
  def initialize
    super('form')
    @attributes['method'] = 'POST'
  end

  html_attr 'action'
  html_attr 'enctype'

  alias __set_url action
  alias callback __actionurl_callback
  alias named_callback __actionurl_named_callback

  def onsubmit_update(update_id, symbol=nil, *args, &block)
    raise ArgumentError if symbol and block
    url = @canvas.url_for_callback(to_callback(symbol, args, block), :live_update)
    onsubmit("javascript: new Ajax.Updater('#{ update_id }', '#{ url }', {method:'get', parameters: Form.serialize(this)}); return false;")
  end

  def with(*args, &block)
    # If no action was specified, use a dummy one.
    unless @attributes.has_key?('action')
      @attributes['action'] = @canvas.build_url
    end
    super
  end
end

class AnchorTag < GenericTagBrush
  def initialize
    super('a')
  end

  html_attr 'href', :aliases => [:url]
  html_attr 'title', :aliases => [:tooltip]

  alias __set_url url

  def info(info=nil)
    @info = info
    self
  end

  def callback(symbol=nil, *args, &block)
    if @info
      __set_url(@canvas.url_for_callback(to_callback(symbol, args, block), :action, :info => @info))
    else
      __set_url(@canvas.url_for_callback(to_callback(symbol, args, block)))
    end
  end

  def named_callback(name, symbol=nil, *args, &block)
    if @info
      __set_url(@canvas.url_for_named_callback(name, to_callback(symbol, args, block), :info => @info))
    else
      __set_url(@canvas.url_for_named_callback(name, to_callback(symbol, args, block)))
    end
  end

end

class Page < Brush
  def title(t)
    @title = t
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

end # class Brush

end # module Wee
