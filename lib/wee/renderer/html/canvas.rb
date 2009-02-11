module Wee

module CanvasMixin
  def initialize_canvas
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

class HtmlCanvasRenderer < Renderer
  include CanvasMixin

  attr_reader :document

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

  def initialize(context, current_component=nil, &block)
    # cache the document, to reduce method calls
    @document = context.document 

    initialize_canvas
    super
  end

  generic_tag :html, :head, :body, :title, :style, :h1, :h2, :h3, :h4, :h5, :div
  generic_tag :div, :span, :ul, :ol, :li
  generic_single_tag :link, :hr

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

  def hidden_input(*args, &block)
    handle(Brush::HiddenInputTag.new, *args, &block)
  end

  def password_input(*args, &block)
    handle(Brush::PasswordInputTag.new, *args, &block)
  end

  def text_input(*args, &block)
    handle(Brush::TextInputTag.new, *args, &block)
  end

  def new_radio_group
    Wee::Brush::RadioButtonTag::RadioGroup.new(self)
  end

  def radio_button(*args, &block)
    handle(Brush::RadioButtonTag.new, *args, &block)
  end

  def check_box(*args, &block)
    handle(Wee::Brush::CheckboxTag.new, *args, &block)
  end

  alias checkbox check_box

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

  def javascript(*args, &block)
    handle(Brush::JavascriptTag.new, *args, &block)
  end

  def paragraph(*args, &block)
    handle(Brush::GenericTagBrush.new("p"), *args, &block)
  end

  def label(*args, &block)
    handle(Brush::GenericTagBrush.new("label"), *args, &block)
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

  # converts \n into <br/>
  def multiline_text(text, encode=true)
    meth = encode ? :encode_text : :text
    lines = text.split("\n")
    send(meth, lines.first)
    lines[1..-1].each { |l| self.break; send(meth, l) }
  end

  def render(obj)
    self.close
    obj.decoration.render_on(@context)
    nil
  end

  require 'erb'

  def template(filename)
    raise "Template file #{ filename } not found!" unless File.exists?(filename)
    self.close
    compiler = ERB::Compiler.new(nil)
    compiler.put_cmd = 'r << '
    src = compiler.compile(File.read(filename))
    if $DEBUG
      puts "-------------------------"
      puts src
      puts "-------------------------"
    end
    @current_component.instance_eval(src, '(erb)', 1) 
    return nil
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
