class Wee::Decoration
  attr_accessor :next   # next decoration in chain
end

class Wee::Delegate < Wee::Decoration

  def initialize(component)
    @component = component
  end

  def process_request(context)
    @component.decoration.process_request(context)
  end

  # Creates a new renderer for this component and renders it.
  def render_with_context(rendering_context)
    r = renderer_class.new(rendering_context)
    r.current_component = self
    r.render(@component)
  end

  def renderer_class
    # Wee::DummyRenderer
    Wee::HtmlCanvas
  end
end

class Wee::Once < Wee::Decoration
  def initialize
    @process_request_cnt = 0 
    @render_cnt = 0
  end

  def process_request(context)
    raise "once" if @process_request_cnt > 0
    @process_request_cnt += 1
    @next.process_request(context)
  end

  # Creates a new renderer for this component and renders it.
  def render_with_context(rendering_context)
    #raise "once" if @render_cnt > 0
    #@render_cnt += 1
    @next.render_with_context(rendering_context)
  end

  def renderer_class
    Wee::HtmlCanvas
  end
end
