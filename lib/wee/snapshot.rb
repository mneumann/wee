class Object
  def take_snapshot
    snap = Hash.new
    instance_variables.each do |iv|
      snap[iv] = instance_variable_get(iv)
    end
    snap
  end

  def apply_snapshot(snap)
    instance_variables.each do |iv|
      instance_variable_set(iv, snap[iv])
    end
  end
end

class Array
  def take_snapshot
    ObjectSpace.undefine_finalizer(dup)
  end

  def apply_snapshot(snap)
    replace(snap)
  end
end

class String
  def take_snapshot
    ObjectSpace.undefine_finalizer(dup)
  end

  def apply_snapshot(snap)
    replace(snap)
  end
end

class Struct
  def take_snapshot
    snap = Hash.new
    each_pair {|k,v| snap[k] = v}
    snap
  end

  def apply_snapshot(snap)
    snap.each_pair {|k,v| send(k.to_s + "=", v)} 
  end
end
