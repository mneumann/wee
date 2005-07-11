class Object
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
end

module Wee::DupReplaceSnapshotMixin
  def take_snapshot
    dup
  end

  def restore_snapshot(snap)
    replace(snap)
  end
end

class Array; include Wee::DupReplaceSnapshotMixin end 
class String; include Wee::DupReplaceSnapshotMixin end 
class Hash; include Wee::DupReplaceSnapshotMixin end 

class Struct
  def take_snapshot
    snap = Hash.new
    each_pair {|k,v| snap[k] = v}
    snap
  end

  def restore_snapshot(snap)
    snap.each_pair {|k,v| send(k.to_s + "=", v)} 
  end
end
