class Main < Wee::Component

  def initialize
    super()
    @scaffolder = OgScaffolder.new(Recipe)
  end

  def children
    [@scaffolder]
  end

  # --------------------------------------------
  # Rendering
  # --------------------------------------------

  def render
    r.render @scaffolder
  end

end
