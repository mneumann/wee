class PageDecoration < Wee::Decoration
  def do_render(rctx)
    with_renderer_for(rctx) do
      r.page.title('').with { super }
    end
  end
end
