module Wee

  class Brush
    attr_accessor :parent, :canvas

    def initialize
      @parent = @canvas = @closed = nil
    end

    def with(*args, &block)
      @canvas.nest(&block) if block
      @closed = true
      nil
    end

    def close
      with unless @closed
    end

    def self.nesting?() true end
  end

  class Brush::GenericTextBrush < Brush
    def with(text)
      @canvas.document.text(text)
      @closed = true
      nil
    end

    def self.nesting?() false end
  end

  class Brush::GenericEncodedTextBrush < Brush::GenericTextBrush
    def with(text)
      @canvas.document.encode_text(text)
      @closed = true
      nil
    end
  end

  class Brush::GenericTagBrush < Brush
    def self.html_attr(attr, hash={})
      name = hash[:html_name] || attr
      if hash[:type] == :bool
        class_eval %{
          def #{ attr }(bool=true)
            if bool
              @attributes[:"#{ name }"] = nil
            else
              @attributes.delete(:"#{ name }")
            end
            self
          end
        }
      else
        class_eval %{ 
          def #{ attr }(value)
            if value == nil
              @attributes.delete(:"#{ name }")
            else
              @attributes[:"#{ name }"] = value
            end
            self
          end
        }
      end

      (hash[:aliases] || []).each do |a|
        class_eval "alias #{ a } #{ attr }"
      end

      (hash[:shortcuts] || {}).each_pair do |k, v|
        class_eval "def #{ k }() #{ attr }(#{ v.inspect }) end"
      end
    end
  end

  class Brush::GenericTagBrush < Brush
    html_attr :id
    html_attr :name # XXX
    html_attr :css_class, :html_name => :class
    html_attr :css_style, :html_name => :style, :aliases => [:style] 

    def initialize(tag)
      super()
      @tag = tag
      @attributes = Hash.new
    end

    def onclick_callback(&block)
      url = @canvas.url_for_callback(block)
      js = "javascript: document.location.href='#{ url }';"
      onclick(js)
    end

    def onclick_update(update_id, &block)
      url = @canvas.url_for_callback(block)
      js = "javascript: new Ajax.Updater('#{ update_id }', '#{ url }', " \
           "{method:'get'}); return false;"
      onclick(js)
    end

    def with(text=nil, &block)
      doc = @canvas.document
      doc.start_tag(@tag, @attributes)
      doc.text(text) if text
      @canvas.nest(&block) if block
      doc.end_tag(@tag)
      @closed = true
      nil
    end

    def __input_callback(&block)
      name(@canvas.register_callback(:input, block))
    end

    def __action_callback(&block)
      name(@canvas.register_callback(:action, block))
    end

    #
    # The callback id is listed in the URL (not as a form-data field)
    #
    def __actionurl_callback(&block)
      __set_url(@canvas.url_for_callback(block))
    end

    def __set_url(url)
      raise
    end
  end

  class Brush::GenericSingleTagBrush < Brush::GenericTagBrush
    def with
      @canvas.document.single_tag(@tag, @attributes) 
      @closed = true
      nil
    end

    def self.nesting?() false end
  end

  class Brush::ImageTag < Brush::GenericSingleTagBrush
    HTML_TAG = 'img'.freeze

    html_attr :src

    def initialize
      super(HTML_TAG)
    end

    def with
      super
    end
  end

  class Brush::JavascriptTag < Brush::GenericTagBrush
    HTML_TAG = 'script'.freeze
    HTML_TYPE = 'text/javascript'.freeze

    html_attr :src
    html_attr :type

    def initialize
      super(HTML_TAG)
      type(HTML_TYPE)
    end
  end

  #---------------------------------------------------------------------
  # Table
  #---------------------------------------------------------------------

  class Brush::TableTag < Brush::GenericTagBrush
    HTML_TAG = 'table'.freeze

    html_attr :cellspacing

    def initialize
      super(HTML_TAG)
    end
  end  

  class Brush::TableRowTag < Brush::GenericTagBrush
    HTML_TAG = 'tr'.freeze

    html_attr :align, :shortcuts => {
      :align_top => :top, :align_bottom => :bottom
    }

    def initialize
      super(HTML_TAG)
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
      with { @canvas.table_data.col_span(colspan).with(str) }
    end

    def spacer
      with { @canvas.table_data { @canvas.space } }
    end
  end

  class Brush::TableDataTag < Brush::GenericTagBrush
    HTML_TAG = 'td'.freeze

    html_attr :colspan
    html_attr :align, :shortcuts => {
      :align_top => :top,
      :align_bottom => :bottom
    }

    def initialize
      super(HTML_TAG)
    end
  end

  class Brush::TableHeaderTag < Brush::TableDataTag
    HTML_TAG = 'th'.freeze

    def initialize
      super(HTML_TAG)
    end
  end

  #---------------------------------------------------------------------
  # Form
  #---------------------------------------------------------------------

  class Brush::FormTag < Brush::GenericTagBrush
    HTML_TAG = 'form'.freeze
    HTML_METHOD_POST = 'POST'.freeze

    html_attr :action
    html_attr :enctype

    def initialize
      super(HTML_TAG)
      @attributes[:method] = HTML_METHOD_POST
    end

    def with(&block)
      # If no action was specified, use a dummy one.
      unless @attributes.has_key?(:action)
        @attributes[:action] = @canvas.build_url
      end
      super
    end

    alias __set_url action
    alias callback __actionurl_callback

=begin
    def onsubmit_update(update_id, &block)
      raise ArgumentError if symbol and block
      url = @canvas.url_for_callback(block, :live_update)
      onsubmit("javascript: new Ajax.Updater('#{ update_id }', '#{ url }', {method:'get', parameters: Form.serialize(this)}); return false;")
    end
=end
  end

  #---------------------------------------------------------------------
  # Form - Input
  #---------------------------------------------------------------------

  class Brush::InputTag < Brush::GenericSingleTagBrush
    HTML_TAG = 'input'.freeze

    html_attr :type
    html_attr :name
    html_attr :value
    html_attr :size
    html_attr :maxlength
    html_attr :src
    html_attr :checked,  :type => :bool
    html_attr :disabled, :type => :bool
    html_attr :readonly, :type => :bool

    def initialize(_type)
      super(HTML_TAG)
      type(_type)
    end

    def with
      super
    end

    alias callback __input_callback
  end

  class Brush::TextInputTag < Brush::InputTag
    HTML_TYPE = 'text'.freeze

    def initialize
      super(HTML_TYPE)
    end
  end

  class Brush::HiddenInputTag < Brush::InputTag
    HTML_TYPE = 'hidden'.freeze

    def initialize
      super(HTML_TYPE)
    end
  end

  class Brush::PasswordInputTag < Brush::InputTag
    HTML_TYPE = 'password'.freeze

    def initialize
      super(HTML_TYPE)
    end
  end

  class Brush::CheckboxTag < Brush::InputTag
    HTML_TYPE = 'checkbox'.freeze

    def initialize
      super(HTML_TYPE)
    end
  end

  class Brush::FileUploadTag < Brush::InputTag
    HTML_TYPE = 'file'.freeze

    def initialize
      super(HTML_TYPE)
    end
  end

  #---------------------------------------------------------------------
  # Form - Buttons
  #---------------------------------------------------------------------

  class Brush::ActionInputTag < Brush::InputTag
    alias callback __action_callback
  end

  class Brush::SubmitButtonTag < Brush::ActionInputTag
    HTML_TYPE = 'submit'.freeze

    def initialize
      super(HTML_TYPE)
    end
  end

  #
  # NOTE: The form-fields returned by a image-button-tag is browser-specific.
  # Most browsers do not send the "name" key together with the value specified
  # by "value", only "name.x" and "name.y". This conforms to the standard. But
  # Firefox also sends "name"="value". This is why I raise an exception from
  # the #value method. Note that it's neccessary to parse the passed
  # form-fields and generate a "name" fields in the request, to make this
  # image-button work. 
  #
  class Brush::ImageButtonTag < Brush::ActionInputTag
    HTML_TYPE = 'image'.freeze

    def initialize
      super(HTML_TYPE)
    end

    undef :value
  end

  #---------------------------------------------------------------------
  # Form - Textarea
  #---------------------------------------------------------------------

  class Brush::TextAreaTag < Brush::GenericTagBrush
    HTML_TAG = 'textarea'.freeze

    html_attr :name
    html_attr :rows
    html_attr :cols
    html_attr :tabindex
    html_attr :accesskey
    html_attr :onfocus
    html_attr :onblur
    html_attr :onselect
    html_attr :onchange
    html_attr :disabled, :type => :bool
    html_attr :readonly, :type => :bool

    def initialize
      super(HTML_TAG)
    end

    def value(val)
      @value = val
      self
    end

    def with(value=nil)
      super(value || @value)
    end

    alias callback __input_callback
  end
  
  #---------------------------------------------------------------------
  # Form - Select
  #---------------------------------------------------------------------

  class Brush::SelectListTag < Brush::GenericTagBrush
    HTML_TAG = 'select'.freeze

    html_attr :size
    html_attr :disabled, :type => :bool
    html_attr :readonly, :type => :bool
    html_attr :multiple, :type => :bool, :aliases => [:multi]

    def initialize(items)
      super(HTML_TAG)
      @items = items
    end

    def items(items)
      @items = items
      self
    end

    def selected(arg=nil, &block)
      raise ArgumentError if arg and block
      @selected = block || arg
      self
    end

    def labels(arg=nil, &block)
      raise ArgumentError if arg and block
      if block
        @labels = proc {|i| block.call(@items[i])}
      else
        @labels = arg
      end
      self
    end

    def callback(&block)
      @callback = block 
      self
    end

    # XXX
    def with
      @labels ||= @items.collect {|i| i.to_s}

      is_multiple = @attributes.has_key?(:multiple)

      if @callback
        # A callback was specified. We have to wrap it inside another
        # callback, as we want to perform some additional actions.
        __input_callback {|input|
          input = [input] unless input.kind_of?(Array)

          choosen = input.map {|idx|
            idx = Integer(idx)
            raise "invalid index in select list" if idx < 0 or idx > @items.size
            @items[idx]
          }
          if choosen.size > 1 and not is_multiple
            raise "choosen more than one element from a non-multiple select list" 
          end
          @callback.call(is_multiple ? choosen : choosen.first)
        }
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

  class Brush::SelectOptionTag < Brush::GenericTagBrush
    HTML_TAG = 'option'.freeze

    html_attr :value
    html_attr :selected, :type => :bool

    def initialize
      super(HTML_TAG)
    end
  end

  #---------------------------------------------------------------------
  # Form - Radio
  #---------------------------------------------------------------------

  class Brush::RadioGroup
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

  class Brush::RadioButtonTag < Brush::InputTag
    HTML_TYPE = 'radio'.freeze

    def initialize
      super(HTML_TYPE)
    end

    def group(radio_group)
      @group = radio_group
      self
    end

    def callback(&block)
      @callback = block
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

  #---------------------------------------------------------------------
  # Misc
  #---------------------------------------------------------------------

  class Brush::AnchorTag < Brush::GenericTagBrush
    HTML_TAG = 'a'.freeze

    html_attr :href,  :aliases => [:url]
    html_attr :title, :aliases => [:tooltip]

    def initialize
      super(HTML_TAG)
    end

    def info(info=nil)
      @info = info
      self
    end

    def callback(&block)
      if @info
        __set_url(@canvas.url_for_callback(block, :action, :info => @info))
      else
        __set_url(@canvas.url_for_callback(block))
      end
    end

    alias __set_url url
  end

  class Brush::Page < Brush
    HTML_HTML = 'html'.freeze
    HTML_HEAD = 'head'.freeze
    HTML_TITLE = 'title'.freeze
    HTML_BODY = 'body'.freeze

    def with(text=nil, &block)
      doc = @canvas.document
      doc.start_tag(HTML_HTML)
      doc.start_tag(HTML_HEAD)

      if @title
        doc.start_tag(HTML_TITLE)
        doc.text(@title)
        doc.end_tag(HTML_TITLE)
      end

      doc.end_tag(HTML_HEAD)
      doc.start_tag(HTML_BODY)

      if text
        raise ArgumentError if block
        doc.text(text)
      else
        @canvas.nest(&block) if block 
      end

      doc.end_tag(HTML_BODY)
      doc.end_tag(HTML_HTML)

      @closed = true
      nil
    end

    def title(t)
      @title = t
      self
    end
  end

end # module Wee
