class Main < Wee::Component

  def initialize
    super()
    # Put your own initialization code below...
  end

  # --------------------------------------------
  # Rendering 
  # --------------------------------------------

  def render
    r.anchor.callback(:click).with { r.h1("Welcome to Wee!") }
    r.text "#{ @clicks || 'No' } clicks"
  end

  # --------------------------------------------
  # Actions 
  # --------------------------------------------

  def click
    @clicks = (@clicks || 0) + 1
  end

end
