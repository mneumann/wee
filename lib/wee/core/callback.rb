# The callback registry is the central datastructure where all components of a
# session register their callbacks.
#
# The format of the internal datastructure is:
#
#   @callbacks[type][callback_id] => callback
#   @obj_to_id_map[type][object] => [id*]

class Wee::CallbackRegistry

  def initialize(id_generator)
    @idgen = id_generator
    @callbacks = Hash.new
    @obj_to_id_map = Hash.new
  end

  # Register +callback+ for +object+ under +type+ and return a unique callback id. 

  def register_for(object, type=nil, &callback)
    c = (@callbacks[type] ||= Hash.new)
    o = (@obj_to_id_map[type] ||= Hash.new) 
    cid = @idgen.next.to_s
    raise "duplicate callback id" if c.has_key?(cid)
    c[cid] = callback
    (o[object] ||= []) << cid  
    return cid
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  # :section: Friend methods for Wee::CallbackStream
  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  def get_ids_for(object, type=nil)
    if o = @obj_to_id_map[type]
      o[object] || []
    else
      []
    end
  end

  def get_callback_for(id, type=nil)
    if c = @callbacks[type]
      c[id]
    else
      raise
    end
  end

  def all_of_type(type=nil)
    if c = @callbacks[type]
      c
    else
      raise
    end
  end

end


# The intersection of registered callbacks and those that occured. 

class Wee::CallbackStream
  
  #
  # [<tt>callbacks</tt>]
  #   A Wee::CallbackRegistry
  #
  # [<tt>ids_and_values</tt>]
  #   A hash that contains all callback ids together with their values that
  #   occurend in a request, e.g. { id => value }.

  def initialize(callbacks, ids_and_values)
    @callbacks = callbacks
    @ids_and_values = ids_and_values
    @ids = @ids_and_values.keys 
  end

  def with_callbacks_for(object, type)
    matching_ids = @callbacks.get_ids_for(object, type) & @ids 
    matching_ids.each do |id|
      yield @callbacks.get_callback_for(id, type), @ids_and_values[id] 
    end
    @ids -= matching_ids
  end

  # Returns a [callback, value] array of all callbacks of +type+ for which an
  # id was given. 

  def all_of_type(type)
    a = [] 
    @callbacks.all_of_type(type).each {|id, callback|
      a << [callback, @ids_and_values[id]]  if @ids_and_values.include?(id)
    }
    return a
  end

end
