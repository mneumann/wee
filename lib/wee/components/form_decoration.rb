class Wee::FormDecoration < Wee::WrapperDecoration
  private

  def render_wrapper
    r.form { yield }
  end
end
