class Wee::Examples::Counter < Wee::Component
  attr_accessor :count

  def initialize(initial_count=0)
    super()
    @count = initial_count 
  end

  def backtrack_state(state)
    super
    state.add_ivar(self, :@count, @count)
  end

  def dec
    @count -= 1
  end

  def inc
    @count += 1
  end

  def render(r)
    r.anchor.callback { dec }.with("--")
    r.space
    render_count(r)
    r.space 
    r.anchor.callback { inc }.with("++")
  end

  def render_count(r)
    r.text @count.to_s
  end
end
