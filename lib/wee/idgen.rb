# Returned ids are guaranteed to be unique, but they are easily guessable.

class Wee::SimpleIdGenerator
  def initialize(initial_value=0)
    @value = initial_value
  end

  def next
    @value += 1
  end
end
