# Superclass of all callback handlers.

class Wee::Callback
  attr_accessor :object # Callback registered for _object_
  attr_accessor :values # An array of values passed during invoke 

  # shortcut

  def self.[](*args)
    new(*args)
  end

  def initialize(object, *values)
    @object, @values = object, values
  end

  # Creates a new callback object, with new values.
  # Don't overwrite the values, if some were given.

  def new_with_values(*values)
    obj = dup
    obj.values = values if @values.empty?
    obj
  end
end

class Wee::MethodCallback < Wee::Callback
  attr_accessor :meth

  def initialize(obj, meth, *values)
    super(obj, *values)
    @meth = meth
  end

  def invoke
    m = @object.method(@meth)
    if m.arity == 0 
      m.call
    else
      m.call(*@values)
    end
  end
end

# The intersection of registered callbacks and those that occured. Can be
# created with method <i>CallbackRegistry#create_callback_stream</i>.

class Wee::CallbackStream
  
  # [+stream+]
  #    A Hash object with shape "type -> object -> [callback*]" 

  def initialize(stream)
    @stream = stream 
  end

  def get_callbacks_for(object, type)
    @stream[type][object]
  end

end


class Wee::CallbackRegistry

  # format of @callbacks:
  #   @callbacks[type][callback_id] # => callback

  def initialize
    @next_callback_id = 1
    @callbacks = Hash.new
  end

  # Registers +callback+ under +type+ and returns a unique callback id. 

  def register(callback, type=nil)
    c = (@callbacks[type] ||= Hash.new)
    cid = get_next_callback_id() 
    raise "duplicate callback id!" if c.has_key?(cid)
    c[cid] = callback
    return cid
  end

  # Create a CallbackStream for this CallbackRegistry, for the given
  # +callback_ids+ argument.
  #
  # [+callback_ids+]
  #    A hash that contains all callback id's together with it's values that
  #    occurend e.g. in a request.

  def create_callback_stream(callback_ids) 
    cids = callback_ids.keys
    cs = Hash.new { Hash.new { Array.new } }

    @callbacks.each_pair do |type, reg|
      h = cs[type]

      # find those callback-ids that occur in both callback_ids and reg.keys
      matching = reg.keys & cids
      #cids -= matching

      matching.each do |cid|
        callback = reg[cid]
        obj = callback.object
        val = callback_ids[cid]
        new_callback = 
        if val.nil?
          callback
        else
          callback.new_with_values(val)
        end
        a = h[obj]
        a << new_callback
        h[obj] = a
      end

      cs[type] = h
    end

    #raise "non-registered callback id(s) specified" unless cids.empty? 
    Wee::CallbackStream.new(cs)
  end

  private

  # TODO: randomize
  def get_next_callback_id
    @next_callback_id.to_s
  ensure
    @next_callback_id += 1
  end

end
