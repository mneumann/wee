class Page < Wee::Component
  attr_reader :children

  def initialize(*children)
    @children = children
  end
  
  def render
    r.page.title('').with {
      self.children.each do |child|
        r.render(child)
      end
    }
  end
end
