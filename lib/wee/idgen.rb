class Wee::SimpleIdGenerator
  def initialize(inital_value=0)
    @value = initial_value
  end

  def current
    @value
  end

  def next
    @value += 1
  end
end
