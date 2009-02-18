require 'wee/components/wrapper_decoration'

module Wee
  class FormDecoration < WrapperDecoration
    def render(r)
      r.form { render_inner(r) }
    end
  end
end
