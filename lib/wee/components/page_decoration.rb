class Wee::PageDecoration < Wee::WrapperDecoration
  def initialize(title='')
    @title = title
    super()
  end

  def global?() true end

  private

  def render_wrapper(r)
    r.page.title(@title).with { yield }
  end
end
