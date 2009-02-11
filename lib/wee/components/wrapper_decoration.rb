class Wee::WrapperDecoration < Wee::Decoration
  def render_on(rendering_context)
    with_renderer_for(rendering_context) do
      render_wrapper { super(rendering_context) }
    end
  end
end
