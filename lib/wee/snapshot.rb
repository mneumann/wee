# This class is for backtracking the state of components (or
# decorations/presenters).  Components that want an undo-facility to be
# implemented (triggered for example by a browsers back-button), have to
# overwrite the Component#backtrack_state method. Class Wee::Snapshot simply
# represents a collection of objects from which snapshots were taken via
# methods take_snapshot. 

class Wee::Snapshot
  def initialize
    @objects = Hash.new
  end

  def add(object)
    oid = object.object_id
    @objects[oid] = [object, object.take_snapshot] unless @objects.include?(oid) 
  end

  def restore
    @objects.each_value { |object, value| object.restore_snapshot(value) }
  end
end
