class Wee::LoginDecoration < Wee::Decoration
  def initialize(login_page)
    @login_page = login_page
  end

  def process_callbacks(&block)
    if logged_in?
      super
    else
      @login_page.decoration.process_callbacks(&block)
    end
  end

  def render_on(context)
    if logged_in?
      super
    else
      @login_page.decoration.render_on(context)
    end
  end

  def backtrack_state(snapshot)
    if logged_in?
      super
    else
      @login_page.decoration.backtrack_state(snapshot)
    end
  end

  # Overwrite this method!

  def logged_in?
    raise "subclass responsibility"
  end
end
