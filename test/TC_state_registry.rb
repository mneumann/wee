require 'test/unit'
$LOAD_PATH.unshift "../lib"
module Wee; end
require 'wee/state_registry'

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

    obj = [1,2,3]
    s.register(obj)

    assert_equal [1,2,3], obj
    snaps << s.snapshot

    obj.push(10)
    assert_equal [1,2,3,10], obj
    snaps << s.snapshot

    snaps[0].apply
    assert_equal [1,2,3], obj

    snaps[1].apply
    assert_equal [1,2,3,10], obj

    snaps[0].apply
    assert_equal [1,2,3], obj

    # marshal ----------------------------

    str = Marshal.dump([s, obj, snaps])
    s, obj, snaps = nil, nil, nil
    s, obj, snaps = Marshal.load(str)

    assert_equal [1,2,3], obj

    snaps[0].apply
    assert_equal [1,2,3], obj

    snaps[1].apply
    assert_equal [1,2,3,10], obj

    snaps[0].apply
    assert_equal [1,2,3], obj
  end
end
