# This class is for backtracking the state of components (or
# decorations/presenters).  Components that want an undo-facility to be
# implemented (triggered for example by a browsers back-button), have to
# overwrite the Component#backtrack_state method. Class Wee::Snapshot simply
# represents a collection of objects from which snapshots were taken via
# methods take_snapshot. 
#
# NOTE that we have to store the object reference also in the value of a hash
# entry and not only as the key of a hash, as hash keys behave differently
# whether it's a String or not-String object. See [ruby-talk:123491].

class Wee::Snapshot
  def initialize
    @objects = Hash.new
  end

  def add(object)
    @objects[object] = [object, object.take_snapshot] unless @objects.include?(object)
  end

  def restore
    @objects.each_value { |object, value| object.restore_snapshot(value) }
  end
end
