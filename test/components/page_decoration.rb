class PageDecoration < Wee::Decoration
  def render(rctx)
    with_renderer_for(rctx) do |r|
      r.page.title('').with { super }
    end
  end
end
