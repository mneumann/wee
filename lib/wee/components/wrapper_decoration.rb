class Wee::WrapperDecoration < Wee::Decoration
  def render_on(context)
    render_wrapper(renderer_class.new(context, self)) { super(context) }
  end

  def render_wrapper(r)
    yield
  end
end
