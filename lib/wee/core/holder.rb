class Wee::ValueHolder 
  attr_accessor :value

  def initialize(value=nil)
    @value = value
  end

  def take_snapshot
    [@value]
  end

  def apply_snapshot(snap)
    @value = snap[0]
  end
end

class Wee::StateHolder < Wee::ValueHolder
  def initialize(value)
    super
    Wee::Session.current.register_object_for_backtracking(self)
  end
end
