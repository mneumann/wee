require 'wee/decoration'

module Wee
  class WrapperDecoration < Decoration
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
