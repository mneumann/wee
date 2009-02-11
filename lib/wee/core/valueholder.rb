module Wee
  #
  # Implements a value holder. Useful for backtracking the reference
  # assigned to an instance variable (not the object itself!). An
  # example where this is used is the <tt>@__decoration</tt> instance
  # variable of class Wee::Component.
  #
  class ValueHolder 
    attr_accessor :value

    def initialize(value=nil)
      @value = value
    end

    def take_snapshot
      @value
    end

    def restore_snapshot(value)
      @value = value
    end
  end # class ValueHolder

end # module Wee
