require 'wee/renderer'

module Wee

  class HtmlCanvasRenderer < Renderer

    def initialize(context, current_component=nil, &block)
      # cache the document, to reduce method calls
      @document = context.document 

      @parent_brush = nil
      @current_brush = nil
      super
    end

    def close
      @current_brush.close if @current_brush
      @current_brush = nil
    end

    def set_brush(brush)
      # tell previous brush to finish
      @current_brush.close if @current_brush

      brush.setup(@parent_brush, self, @document)
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

    generic_tag :html, :head, :body, :title, :style, :label
    generic_tag :h1, :h2, :h3, :h4, :h5
    generic_tag :div, :span, :ul, :ol, :li
    generic_single_tag :link, :hr

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

    HTML_TYPE_CSS = 'text/css'.freeze
    HTML_REL_STYLESHEET = 'stylesheet'.freeze

    def link_css(url)
      link.type(HTML_TYPE_CSS).rel(HTML_REL_STYLESHEET).href(url)
    end

    def render(obj)
      @current_brush.close if @current_brush
      @current_brush = nil
      obj.decoration.render_on(@context)
      nil
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
      context.request.build_url(*args)
    end

    def register_callback(type, callback)
      cbs = self.context.callbacks
      if cbs.respond_to?("#{type}_callbacks")
        cbs.send("#{type}_callbacks").register(self.current_component, callback)
      else
        raise
      end
    end

    protected

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

  end # class HtmlCanvasRenderer

end # module Wee
