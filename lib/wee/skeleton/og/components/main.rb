class Main < Wee::Component

  def initialize
    super()
    @scaffolder = add_child OgScaffolder.new(Recipe)
  end

  # --------------------------------------------
  # Rendering
  # --------------------------------------------

  def render
    r.render @scaffolder
  end

end
