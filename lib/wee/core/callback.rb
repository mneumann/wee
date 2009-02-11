module Wee

  class CallbackRegistry
    def initialize(prefix="")
      @prefix = prefix
      @callbacks = []    # [callback1, callback2, ...]
      @triggered = nil
      @obj_map = {}      # obj => [callback_id1, callback_id2, ...]
    end

    def register(object, callback)
      id = @callbacks.size
      @callbacks << callback
      (@obj_map[object] ||= []) << id
      return "#{@prefix}#{id}"
    end

    def with_triggered(ids_and_values)
      @triggered = {}
      ids_and_values.each do |id, value|
        if id =~ /^#{@prefix}(\d+)$/
          id = Integer($1)
          next if id > @callbacks.size
          @triggered[id] = value 
        end
      end
      yield self
    ensure
      @triggered = nil
    end

    def each_triggered(object)
      if ary = @obj_map[object]
        ary.each do |id|
          yield @callbacks[id], @triggered[id] if @triggered.has_key?(id)
        end
      end
    end

  end # class CallbackRegistry

  class Callbacks
    attr_reader :input_callbacks
    attr_reader :action_callbacks

    def initialize
      @input_callbacks = CallbackRegistry.new("")
      @action_callbacks = CallbackRegistry.new("a")
    end
  end # class Callbacks

end # module Wee

#
# A serializable callback. 
#
class Wee::LiteralMethodCallback
  attr_reader :obj

  def initialize(obj, method_id=:call, *args)
    @obj, @method_id = obj, method_id
    @args = args unless args.empty?
  end

  def call(*args)
    if @args
      @obj.send(@method_id, *(@args+args))
    else
      @obj.send(@method_id, *args)
    end
  end
end
