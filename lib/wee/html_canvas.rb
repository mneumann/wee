require 'wee/renderer'

module Wee

  class HtmlCanvas < Renderer

    def initialize(*args)
      super
      @current_brush = nil
    end

    def close
      @current_brush.close if @current_brush
      @current_brush = nil
    end

    def nest
      old_brush = @current_brush
      # we don't want that Brush#close is calledas #nest
      # is called from #with -> this avoids an infinite loop
      @current_brush = nil 
      yield
      @current_brush.close if @current_brush
      @current_brush = old_brush
    end

    def self.brush_tag(attr, klass, *args_to_new)
      args_to_new = args_to_new.map {|a| a.inspect}.join(", ")
      if klass.instance_method(:with).arity != 0
        class_eval %{ 
          def #{attr}(*args, &block)
            handle(#{klass}.new(#{args_to_new}), *args, &block)
          end
        }
      elsif klass.nesting?
        class_eval %{ 
          def #{attr}(&block)
            handle2(#{klass}.new(#{args_to_new}), &block)
          end
        }
      else
        class_eval %{ 
          def #{attr}
            handle3(#{klass}.new(#{args_to_new}))
          end
        }
      end
    end 

    def self.generic_tag(*attrs)
      attrs.each {|attr| brush_tag attr, Brush::GenericTagBrush, attr }
    end

    def self.generic_single_tag(*attrs)
      attrs.each {|attr| brush_tag attr, Brush::GenericSingleTagBrush, attr }
    end

    generic_tag :html, :head, :body, :title, :label
    generic_tag :h1, :h2, :h3, :h4, :h5
    generic_tag :div, :span, :ul, :ol, :li, :pre
    generic_single_tag :hr

    brush_tag :link, Brush::LinkTag
    brush_tag :table, Brush::TableTag
    brush_tag :table_row, Brush::TableRowTag
    brush_tag :table_data, Brush::TableDataTag
    brush_tag :table_header, Brush::TableHeaderTag
    brush_tag :form, Brush::FormTag
    brush_tag :input, Brush::InputTag
    brush_tag :hidden_input, Brush::HiddenInputTag
    brush_tag :password_input, Brush::PasswordInputTag
    brush_tag :text_input, Brush::TextInputTag
    brush_tag :radio_button, Brush::RadioButtonTag
    brush_tag :check_box, Brush::CheckboxTag; alias checkbox check_box
    brush_tag :text_area, Brush::TextAreaTag
    brush_tag :option, Brush::SelectOptionTag
    brush_tag :submit_button, Brush::SubmitButtonTag
    brush_tag :image_button, Brush::ImageButtonTag
    brush_tag :file_upload, Brush::FileUploadTag
    brush_tag :page, Brush::Page
    brush_tag :anchor, Brush::AnchorTag
    brush_tag :javascript, Brush::JavascriptTag
    brush_tag :image, Brush::ImageTag
    brush_tag :style, Brush::StyleTag

    brush_tag :bold, Brush::GenericTagBrush, :b
    brush_tag :paragraph, Brush::GenericTagBrush, :p
    brush_tag :break, Brush::GenericSingleTagBrush, :br

    def select_list(items, &block)
      handle2(Brush::SelectListTag.new(items), &block)
    end

    HTML_NBSP = "&nbsp;".freeze

    def space(n=1)
      text(HTML_NBSP*n)
    end

    def text(str)
      @current_brush.close if @current_brush
      @current_brush = nil
      @document.text(str)
      nil
    end

    alias << text

    def encode_text(str)
      @current_brush.close if @current_brush
      @current_brush = nil
      @document.encode_text(str)
      nil
    end

    def css(str)
      style.type('text/css').with(str)
    end

    #
    # Depends on an existing divert location :styles.
    #
    def render_style(component)
      once(component.class) { try_divert(:styles, component.style) }
    end

    #
    # converts \n into <br/>
    #
    def multiline_text(str, encode=true)
      @current_brush.close if @current_brush
      @current_brush = nil

      first = true
      str.each_line do |line|
        @document.single_tag(:br) unless first
        first = false

        if encode
          @document.encode_text(line)
        else
          @document.text(line)
        end
      end 
    end

    #
    # Define a divert location
    #
    def define_divert(tag)
      @document.define_divert(tag)
    end

    #
    # Change into an existing divert location and 
    # append +txt+ or the contents of +block+.
    #
    def divert(tag, txt=nil, &block)
      @document.divert(tag, txt, &block)
    end

    #
    # If the divert +tag+ exists, divert, otherwise
    # do nothing.
    #
    def try_divert(tag, txt=nil, &block)
      if @document.has_divert?(tag)
        divert(tag, txt, &block)
        true
      else
        false
      end
    end

    #
    # Render specific markup only once. For example style and/or
    # javascript of a component which has many instances.
    #
    def once(tag)
      return if  @document.set.has_key?(tag)
      @document.set[tag] = true
      yield if block_given? 
    end

    HTML_TYPE_CSS = 'text/css'.freeze
    HTML_REL_STYLESHEET = 'stylesheet'.freeze

    def link_css(url)
      link.type(HTML_TYPE_CSS).rel(HTML_REL_STYLESHEET).href(url)
    end

    def new_radio_group
      Wee::Brush::RadioButtonTag::RadioGroup.new(self)
    end

    def url_for_callback(callback, type=:action, hash=nil)
      url_for_callback_id(register_callback(type, callback), hash)
    end

    def url_for_callback_id(callback_id, hash=nil)
      if hash
        build_url(hash.update(:callback_id => callback_id))
      else
        build_url(:callback_id => callback_id)
      end
    end

    def build_url(*args)
      @request.build_url(*args)
    end

    def register_callback(type, callback)
      cbs = @callbacks
      if cbs.respond_to?("#{type}_callbacks")
        cbs.send("#{type}_callbacks").register(@current_component, callback)
      else
        raise
      end
    end

    protected

    def set_brush(brush)
      brush.setup(self, @document)

      @current_brush.close if @current_brush
      @current_brush = brush

      return brush
    end

    def handle(brush, *args, &block)
      if block or not args.empty?
        set_brush(brush)
        brush.with(*args, &block) 
      else
        set_brush(brush)
      end
    end

    def handle2(brush, &block)
      if block
        set_brush(brush)
        brush.with(&block) 
      else
        set_brush(brush)
      end
    end

    alias handle3 set_brush

  end # class HtmlCanvas

end # module Wee
