require 'thread'
require 'set'
require 'wee/snapshot'

class Wee::StateRegistry
  def initialize
    @registered_objects = Hash.new  # { oid => Set:{snap_oid1, snap_oid2}
    @snap_to_oid_map = Hash.new     # { snap_oid => Set:{oid1, oid2} }

    @finalizer_snap = proc {|snap_oid|
      Thread.exclusive do
        @snap_to_oid_map[snap_oid].each do |oid|
          if r = @registered_objects[oid]
            r.delete(snap_oid)
          end
        end
        @snap_to_oid_map.delete(snap_oid)
      end
    }

    @finalizer_obj = proc {|oid|
      Thread.exclusive do
        (@registered_objects.delete(oid) || []).each do |snap_oid|
          with_object(snap_oid) { |snap|
            snap.delete(oid)
            @snap_to_oid_map[snap_oid].delete(oid)
          }
        end
      end
    }
  end

  def marshal_load(dump)
    initialize
    objs, snaps = dump

    objs.each do |obj|
      register(obj)
    end

    snaps.each do |snap|
      set = (@snap_to_oid_map[snap.object_id] ||= Set.new)

      snap.each do |oid, hash| 
        set.add(oid)
        @registered_objects[oid].add(snap.object_id)
      end

      ObjectSpace.define_finalizer(snap, @finalizer_snap)
    end
  end

  # TODO: should do a GC before marshalling?! 
  # NOTE: we have to marshal the @registered_objects too, as we might have not
  # yet taken any snapshot
  def marshal_dump
    objs = []
    snaps = []

    each_object {|obj| objs << obj}
    each_snapshot { |snap| snaps << snap }

    [objs, snaps]
  end

  def snapshot
    snap = Snapshot.new
    set = (@snap_to_oid_map[snap.object_id] ||= Set.new)

    each_object do |obj|
      snap.add_object(obj)
      set.add(obj.object_id)
      @registered_objects[obj.object_id].add(snap.object_id)
    end

    ObjectSpace.define_finalizer(snap, @finalizer_snap)

    return snap
  end

  def register(obj)
    @registered_objects[obj.object_id] ||= Set.new 
    ObjectSpace.define_finalizer(obj, @finalizer_obj)
  end

  alias << register

  def each_object(&block)
    Thread.exclusive do
      @registered_objects.each_key do |oid|
        with_object(oid, &block)
      end
    end
  end

  def each_snapshot(&block)
    Thread.exclusive do
      @snap_to_oid_map.each_key do |oid|
        with_object(oid, &block)
      end
    end
  end

  private

  def with_object(oid, &block)
    begin
      obj = ObjectSpace._id2ref(oid)
    rescue RangeError
      return
    end
    block.call(obj) if block
  end

  class Snapshot
    def initialize
      @data = Hash.new
    end

    def delete(key)
      @data.delete(key)
    end

    def each(&block)
      Thread.exclusive do
        @data.each(&block)
      end
    end

    def add_object(obj)
      @data[obj.object_id] = obj.take_snapshot
    end

    def apply
      each do |oid, snap|
        with_object(oid) {|obj|
          obj.apply_snapshot(snap)
        }
      end
    end

    def marshal_dump
      # generates a { obj => {instance variables} } hash
      dump = Hash.new

      each do |oid, hash|
        with_object(oid) {|obj| dump[obj] = hash }
      end

      dump
    end

    def marshal_load(dump)
      initialize
      dump.each do |obj, hash|
        @data[obj.object_id] = hash
      end
    end

    private

    def with_object(oid, &block)
      begin
        obj = ObjectSpace._id2ref(oid)
      rescue RangeError
        return
      end
      block.call(obj) if block
    end

  end # class Snapshot

end
