class Wee::Delegate
  attr_accessor :next   # next decoration in chain

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
    Wee::HtmlCanvas
  end
end
