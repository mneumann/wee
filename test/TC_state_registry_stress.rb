$LOAD_PATH.unshift "../lib"
module Wee; end
require 'wee/state_registry'
require 'wee/holder'
require 'test/unit'

def measure_memory(pid=$$)
  mem, res = `ps -p #{ pid } -l`.split("\n").last.strip.split(/\s+/)[6..7]
  return mem.to_i
end

class TC_StateRegistryStress < Test::Unit::TestCase

  def test_stress
    n = 100
    s = Wee::StateRegistry.new
    classes = [Object, String, Hash, Set, Array]

    n.times do
      classes.each do |klass|
        1000.times do
          s << klass.new

          # a cyclic reference
          cyc = Wee::ValueHolder.new
          cyc.value = cyc 
          s << cyc
        end
      end

      s.snapshot
    end

    GC.start
    mem = measure_memory
    stat = s.statistics
    objs, snaps = stat[:registered_objects], stat[:snapshots]

    assert(objs == 0, "all objects should have been garbage collected! (#{ objs })")
    assert(snaps == 0, "all snapshots should have been garbage collected! (#{ snaps })")
    assert(mem < 22_000, "memory consumption (#{ mem }) is higher than 22_000") 
  end

  def test_stress_fail
    n = 10
    s = Wee::StateRegistry.new
    a = []
    classes = [Object, String, Hash, Set, Array]

    n.times do
      classes.each do |klass|
        1000.times do
          obj = klass.new
          s << obj
          a << obj 
        end
      end
      s.snapshot
    end

    GC.start
    mem = measure_memory
    assert(mem > 40_000)
  end
end
