require 'wee/decoration'

module Wee
  class WrapperDecoration < Decoration

    alias render_on render_presenter_on

    #
    # Overwrite this method, and call render_inner(r) 
    # where you want the inner content to be drawn.
    #
    def render(r)
      render_inner(r)
    end

    def render_inner(r)
      r.render_decoration(@next)
    end
  end
end
