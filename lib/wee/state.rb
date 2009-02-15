module Wee

  #
  # This class is for backtracking the state of components (or
  # decorations/presenters).  Components that want an undo-facility to be
  # implemented (triggered for example by a browsers back-button), have to
  # overwrite the Component#backtrack_state method. Class Wee::State simply
  # represents a collection of objects from which snapshots were taken via
  # methods take_snapshot. 
  #
  class State
    class Snapshot < Struct.new(:object, :snapshot); end

    def initialize
      @objects = Hash.new
    end

    def add(object)
      oid = object.object_id
      unless @objects.include?(oid)
        @objects[oid] = Snapshot.new(object, object.take_snapshot)
      end
    end

    alias << add

    def restore
      @objects.each_value {|s| s.object.restore_snapshot(s.snapshot) }
    end
  end # class State

  module DupReplaceSnapshotMixin
    def take_snapshot
      dup
    end

    def restore_snapshot(snap)
      replace(snap)
    end
  end # module DupReplaceSnapshotMixin

  module ObjectSnapshotMixin
    def take_snapshot
      snap = Hash.new
      instance_variables.each do |iv|
        snap[iv] = instance_variable_get(iv)
      end
      snap
    end

    def restore_snapshot(snap)
      instance_variables.each do |iv|
        instance_variable_set(iv, snap[iv])
      end
    end
  end # module ObjectSnapshotMixin

  module StructSnapshotMixin
    def take_snapshot
      snap = Hash.new
      each_pair {|k,v| snap[k] = v}
      snap
    end

    def restore_snapshot(snap)
      snap.each_pair {|k,v| send(k.to_s + "=", v)} 
    end
  end # module StructSnapshotMixin

end # module Wee

#
# Extend base classes with snapshot functionality
#
class Object; include Wee::ObjectSnapshotMixin end
class Struct; include Wee::StructSnapshotMixin end
class Array; include Wee::DupReplaceSnapshotMixin end 
class String; include Wee::DupReplaceSnapshotMixin end 
class Hash; include Wee::DupReplaceSnapshotMixin end 
