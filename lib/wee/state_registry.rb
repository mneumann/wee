require 'set'
require 'wee/snapshot'
require 'thread'

# StateRegistry is not thread-safe! This doesn't matter, as each Wee::Session
# has it's own registry, and each session run's in it's own thread. 

class Wee::StateRegistry

  def initialize
    @registered_objects = Hash.new  # { oid => Set:{snap_oid1, snap_oid2}
    @snap_to_oid_map = Hash.new     # { snap_oid => Set:{oid1, oid2} }

    @finalizer_snap = proc {|snap_oid|
      @snap_to_oid_map[snap_oid].each do |oid|
        if r = @registered_objects[oid]
          r.delete(snap_oid)
        end
      end
      @snap_to_oid_map.delete(snap_oid)
    }

    @finalizer_obj = proc {|oid|
      if r = @registered_objects.delete(oid)
        r.each do |snap_oid|
          with_object(snap_oid) { |snap|
            snap.data.delete(oid)
            @snap_to_oid_map[snap_oid].delete(oid)
          }
        end
      end
    }
  end

  # Register object +obj+. If you call #snapshot, a snapshot of all registered
  # objects is taken.

  def register(obj)
    raise "multi-register" if @registered_objects.include?(obj.object_id)
    @registered_objects[obj.object_id] ||= Set.new 
    ObjectSpace.define_finalizer(obj, @finalizer_obj)
  end
  alias << register

  # Take a snapshot of all registered objects. Returns a
  # StateRegistry::Snapshot data structure.

  def snapshot
    snap = Snapshot.new
    snap_oid = snap.object_id
    set = (@snap_to_oid_map[snap.object_id] ||= Set.new)

    each_object(@registered_objects) do |obj, oid|
      snap.add_object(obj)
      set.add(oid)
      @registered_objects[oid].add(snap_oid)
    end

    ObjectSpace.define_finalizer(snap, @finalizer_snap)
    return snap
  end

  # Returns the current number of registered objects and snapshots.

  def statistics
    {:registered_objects => @registered_objects.size, 
     :snapshots => @snap_to_oid_map.size}
  end

  # ----------------------------------------------------------------------
  # Marshalling
  # ----------------------------------------------------------------------

  def marshal_load(dump)
    initialize
    objs, snaps = dump

    objs.each do |obj|
      register(obj)
    end

    snaps.each do |snap|
      set = (@snap_to_oid_map[snap.object_id] ||= Set.new)

      snap.data.each do |oid, hash| 
        set.add(oid)
        @registered_objects[oid].add(snap.object_id)
      end

      ObjectSpace.define_finalizer(snap, @finalizer_snap)
    end
  end

  # Notice: We have to marshal the @registered_objects too, as we might have
  # not yet taken any snapshot
  #
  # TODO: Should we do a GC before marshalling? Otherwise we marshal possibly
  # unused objects.

  def marshal_dump
    objs = []
    snaps = []

    each_object(@registered_objects) {|obj, oid| objs << obj}
    each_object(@snap_to_oid_map) { |snap, soid| snaps << snap }

    [objs, snaps]
  end

  # ----------------------------------------------------------------------
  # Private and other stuff
  # ----------------------------------------------------------------------

  private

  # Iterate over all live objects in +hash+ where +hash+ may be either
  # @registered_objects or @snap_to_oid_map.

  def each_object(hash, &block) #:yields: object, object_id
    hash.each_key do |oid|
      with_object(oid) {|obj| 

        # At this point, @registered_objects[oid] will not be modified, i.e. no
        # finalizer for oid will be called as we're holding a reference to it.
        # But we might hold a reference to a non-registered object (the
        # "original" registered object was garbage-collected and a new with the
        # same object_id sprang into existence). If it's a different object
        # than the registered one, then a finalizer was called during iterating
        # over @registered_objects (and has been removed from there in the
        # meanwhile).

        block.call(obj, oid) if hash.include?(oid)
      }
    end
  end

  # Mixin that is used in both StateRegistry and StateRegistry::Snapshot 

  module WithObject
    private
    def with_object(oid, &block)
      begin
        obj = ObjectSpace._id2ref(oid)
      rescue RangeError
        return
      end
      block.call(obj) if block
    end
  end

  include WithObject

  # Snapshot is a private data structure used by StateRegistry. You SHOULD NOT
  # use it directly! 

  class Snapshot
    # DO NOT access +data+ directly!
    attr_reader :data

    def initialize
      @data = Hash.new    # { oid => snapshot, ... }
    end

    def add_object(obj)
      @data[obj.object_id] = obj.take_snapshot
    end

    def apply
      each_object_snapshot do |obj, snap|
        obj.apply_snapshot(snap)
      end
    end

    def marshal_dump
      # generates a { obj => {instance variables} } hash
      dump = Hash.new

      each_object_snapshot do |obj, snap|
        dump[obj] = snap
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

    include WithObject

    def each_object_snapshot(&block)
      @data.each do |oid, snap|
        with_object(oid) {|obj| 
          # same is true as for StateRegistry#each_object
          block.call(obj, snap) if @data.include?(oid)
        }
      end
    end

  end # class Snapshot

end
