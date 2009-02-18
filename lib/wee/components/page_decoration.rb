require 'wee/components/wrapper_decoration'

module Wee
  class PageDecoration < WrapperDecoration
    def initialize(title='')
      @title = title
      super()
    end

    def global?() true end

    def render(r)
      r.page.title(@title).with { render_inner(r) }
    end
  end
end
