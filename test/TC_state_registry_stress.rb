$LOAD_PATH.unshift "../lib"
module Wee; end
require 'wee/state_registry'
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
        end
      end
      s.snapshot
    end

    assert measure_memory < 9000
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

    assert measure_memory > 30_000
  end
end
