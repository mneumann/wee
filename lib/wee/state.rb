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
    class Snapshot
      def initialize(object)
        @object = object
        @snapshot = nil
        @has_snapshot = false
        @ivars = nil
      end

      def take
        @snapshot = @object.take_snapshot unless @has_snapshot
        @has_snapshot = true
      end

      def add_ivar(ivar, value)
        @ivars ||= {}
        @ivars[ivar] = value
      end

      def restore
        @object.restore_snapshot(@snapshot) if @has_snapshot
        @ivars.each_pair {|k,v| @object.instance_variable_set(k, v) } if @ivars
      end
    end

    def initialize
      @snapshots = Hash.new
    end

    def add(object)
      (@snapshots[object.object_id] ||= Snapshot.new(object)).take
    end

    def add_ivar(object, ivar, value=object.instance_variable_get(ivar))
      (@snapshots[object.object_id] ||= Snapshot.new(object)).add_ivar(ivar, value)
    end

    alias << add

    def restore
      @snapshots.each_value {|snapshot| snapshot.restore}
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
