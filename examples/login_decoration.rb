class LoginDecoration < Decoration
  def initialize(login_page)
    @login_page = login_page
  end

  def process_callbacks(callbacks)
    if logged_in?
      super
    else
      @login_page.decoration.process_callbacks(callbacks)
    end
  end

  def render_on(context)
    if logged_in?
      super
    else
      @login_page.decoration.render_on(context)
    end
  end

  def backtrack(state)
    if logged_in?
      super
    else
      @login_page.decoration.backtrack(state)
    end
  end

  # Overwrite this method!

  def logged_in?
    raise "subclass responsibility"
  end
end
