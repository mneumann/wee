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

  # Creates a new callback object, with additional values.

  def new_with_values(*values)
    obj = dup
    obj.values = self.values + values
    obj
  end
end

class Wee::MethodCallback < Wee::Callback
  attr_accessor :meth, :args

  def initialize(obj, meth, *args)
    super(obj)
    @meth, @args = meth.to_s, args
  end

  def invoke
    @object.send(@meth, *@args)
  end
end

# The intersection of registered callbacks and those that occured. Can be
# created with method <i>CallbackRegistry#create_callback_stream</i>.

class Wee::CallbackStream
  
  # [+stream+]
  #    A Hash object with shape "type -> component -> [callback*]" 

  def initialize(stream)
    @stream = stream 
  end

  def get_callbacks_for(object, type)
    @stream[type][object]
  end
end

# register_callback(Wee::MethodCallback[obj, :call], :input) 
# @callbacks[type][callback_id] # => callback

class Wee::CallbackRegistry

  def initialize
    @next_callback_id = 1
    @callbacks = Hash.new { Hash.new }
  end

  # Registers +callback+ under +type+ and returns a unique callback id. 

  def register(callback, type=nil)
    c = @callbacks[type]
    cid = get_next_callback_id() 
    raise "duplicate callback id!" if c.has_key?(cid)
    c[cid] = callback
    @callbacks[type] = c
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
      cids -= matching

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

    raise "non-registered callback id(s) specified" unless cids.empty? 
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
