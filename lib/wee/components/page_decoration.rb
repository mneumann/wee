class Wee::PageDecoration < Wee::Decoration
  def initialize(title='')
    @title = title
    super()
  end

  def global?() true end

  def do_render(rendering_context)
    with_renderer_for(rendering_context) do
      r.page.title(@title).with { super(rendering_context) }
    end
  end
end
