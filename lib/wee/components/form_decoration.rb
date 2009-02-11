class Wee::FormDecoration < Wee::WrapperDecoration
  private

  def render_wrapper(r)
    r.form { yield }
  end
end
