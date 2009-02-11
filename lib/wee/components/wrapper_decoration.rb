class Wee::WrapperDecoration < Wee::Decoration
  def render_on(context)
    with_renderer_for(context) do
      render_wrapper { super(context) }
    end
  end
end
