class Wee::PageDecoration < Wee::Decoration
  def initialize(title='')
    @title = title
    super()
  end

  def global?() true end

  def do_render(rendering_context)
    with_renderer_for(rendering_context) do
      render_page { super(rendering_context) }
    end
  end

  private

  def render_page
    r.page.title(@title).with { yield }
  end
end
