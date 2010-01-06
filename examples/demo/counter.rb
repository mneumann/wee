class Counter < Wee::Component
  attr_accessor :count

  def initialize(initial_count=0)
    @count = initial_count
    add_decoration Wee::StyleDecoration.new(self)
  end

  def state(s) super
    s.add_ivar(self, :@count)
  end

  def dec
    @count -= 1
  end

  def inc
    @count += 1
  end

  def style
    ".wee-Counter a { border: 1px dotted blue; margin: 2px; }"
  end

  def render(r)
    r.div.oid.css_class('wee-Counter').with {
      r.anchor.callback_method(:dec).with("--")
      r.space
      render_count(r)
      r.space
      r.anchor.callback_method(:inc).with("++")
    }
  end

  def render_count(r)
    r.text @count.to_s
  end
end
