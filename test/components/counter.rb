class Counter < Wee::Component
  def initialize(cnt=0)
    @cnt = cnt
  end

  def state(s)
    super
    s.add_ivar(:@cnt, @cnt)
  end

  def render
    r.h1(@cnt.value.to_s)
    r.anchor.callback { @cnt.value -= 1 }.with("--")
    r.anchor.callback { @cnt.value += 1 }.with("++")
  end
end
