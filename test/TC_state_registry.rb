require 'test/unit'
$LOAD_PATH.unshift "../lib/wee"
module Wee; end
require 'state_registry'

class TC_StateRegistry < Test::Unit::TestCase
  def test_finalizer
    s = Wee::StateRegistry.new
    10_000.times do 
      s.register("abc")
    end
    s.each_object {|o| assert_equal("abc", o)} 
    ObjectSpace.garbage_collect
    s.each_object {|o| assert_equal("abc", o)} 
  end

  def test_snapshot_marshal
    s = Wee::StateRegistry.new
    snaps = []

    obj = Set[1,2,3]
    s.register(obj)

    assert_equal Set[1,2,3], obj
    snaps << s.take_snapshot

    obj.add(10)
    assert_equal Set[1,2,3,10], obj
    snaps << s.take_snapshot

    s.apply_snapshot(snaps[0])
    assert_equal Set[1,2,3], obj

    s.apply_snapshot(snaps[1])
    assert_equal Set[1,2,3,10], obj

    s.apply_snapshot(snaps[0])
    assert_equal Set[1,2,3], obj

    # marshal ----------------------------

    str = Marshal.dump([s, obj, snaps])
    s, obj, snaps = nil, nil, nil
    s, obj, snaps = Marshal.load(str)

    assert_equal Set[1,2,3], obj

    s.apply_snapshot(snaps[0])
    assert_equal Set[1,2,3], obj

    s.apply_snapshot(snaps[1])
    assert_equal Set[1,2,3,10], obj

    s.apply_snapshot(snaps[0])
    assert_equal Set[1,2,3], obj
  end
end
