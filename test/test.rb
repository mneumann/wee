$LOAD_PATH.unshift "../lib"
module Wee; end
require 'wee/state_registry'
require 'wee/holder'

def measure_memory(pid=$$)
  mem, res = `ps -p #{ pid } -l`.split("\n").last.strip.split(/\s+/)[6..7]
  return mem.to_i
end

class ValueHolder
  def initialize(value)
    @value = value
  end
end
class Component
  def initialize(state)
    @decoration = ValueHolder.new(self)
    state.register @decoration
  end
end

s = Wee::StateRegistry.new
loop do 
  # once a snapshot exists, old registered objects are contained in it, and will never
  # get recycled unless all "later" snapshots are recycled.  

  # the size of each snapshot should increase!

  Component.new(s)

  # a snapshot links back to the object 
  # one a snapshot has been taken, the registered_objects cannot be gc'ed, unless
  # it's former snapshot goes out of scope (gets gc'ed)!
  # One solution: GC before doing a snapshot!

  GC.start
  s.snapshot

  p s.statistics
end

# TODO: use will_call? to optimize  
