class Page < Wee::Component
  def initialize(*children)
    super()
    self.children.push(*children)
  end

  def render_content_on(r)
    r.page.title('').with {
      self.children.each do |child|
        r.render(child)
      end
    }
  end
end
