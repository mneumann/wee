class Wee::Examples::Counter < Wee::Component
  attr_accessor :count

  def initialize(initial_count=0)
    super()
    @count = initial_count 
  end

  def backtrack_state(snap)
    super
    snap.add(self)
  end

  def dec
    @count -= 1
  end

  def inc
    @count += 1
  end

  def render
    r.anchor.callback(:dec).with("--")
    r.space
    render_count
    r.space 
    r.anchor.callback(:inc).with("++")
  end

  def render_count
    r.text @count.to_s
  end
end
