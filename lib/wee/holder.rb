class Wee::ValueHolder 
  attr_accessor :value

  def initialize(value=nil)
    @value = value
  end
end

class Wee::StateHolder < Wee::ValueHolder
  def initialize(value)
    super
    Wee::Session.current.state_registry << self
  end
end
