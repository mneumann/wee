class Counter < Wee::Component
  def initialize(cnt=0)
    super()
    @cnt = ValueHolder.new(cnt) 
  end

  def backtrack_state(snap)
    super
    snap.add(@cnt)
  end

  def render
    r.h1(@cnt.value.to_s)
    r.anchor.callback { @cnt.value -= 1 }.with("--")
    r.anchor.callback { @cnt.value += 1 }.with("++")
  end
end
