module Wee

  #
  # This class is for backtracking the state of components (or
  # decorations/presenters).  Components that want an undo-facility to be
  # implemented (triggered for example by a browsers back-button), have to
  # overwrite the Component#state method. Class Wee::State simply
  # represents a collection of objects from which snapshots were taken via
  # methods take_snapshot.
  #
  class State
    class Snapshot < Struct.new(:object, :snapshot); end
    class SnapshotIVars < Struct.new(:object, :ivars); end

    def initialize
      @objects = Hash.new
      @objects_ivars = Hash.new 
    end

    def add(object)
      @objects[object.object_id] ||= Snapshot.new(object, object.take_snapshot)
    end

    def add_ivar(object, ivar, value)
      (@objects_ivars[object.object_id] ||= SnapshotIVars.new(object, {})).ivars[ivar] = value
    end

    alias << add

    def restore
      @objects.each_value {|s| s.object.restore_snapshot(s.snapshot) }
      @objects_ivars.each_value {|s|
        s.ivars.each {|k,v| s.object.instance_variable_set(k, v) }
      }
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
      snap.each do |k,v|
        instance_variable_set(k, v)
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
