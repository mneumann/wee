class Snapshot
  def initialize
    @objects = Hash.new
  end

  def add(object)
    @objects[object] = object.take_snapshot unless @objects.include?(object)
  end

  def restore
    @objects.each_pair { |object, value| object.restore_snapshot(value) }
  end
end
