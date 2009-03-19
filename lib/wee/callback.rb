module Wee

  class CallbackRegistry
    def initialize(prefix="")
      @prefix = prefix
      @next_id = 0
      @callbacks = {}    # {callback_id1 => callback1, callback_id2 => callback2}
      @triggered = nil
      @obj_map = {}      # obj => [callback_id1, callback_id2, ...]
    end

    def register(object, callback)
      id = @next_id
      @next_id += 1
      @callbacks[id] = callback
      (@obj_map[object] ||= []) << id
      return "#{@prefix}#{id}"
    end

    def unregister(object)
      if arr = @obj_map.delete(object)
        arr.each {|id| @callbacks.delete(id) }
      end
    end

    #
    # NOTE that if fields named "xxx" and "xxx.yyy" occur, the value of 
    # @fields['xxx'] is { nil => ..., 'yyy' => ... }. This is required
    # to make image buttons work correctly.
    #
    def prepare_triggered(ids_and_values)
      @triggered = {}
      ids_and_values.each do |id, value|
        if id =~ /^#{@prefix}(\d+)([.](.*))?$/
          id, suffix = Integer($1), $3
          next unless @callbacks[id]

          if @triggered[id].kind_of?(Hash)
            @triggered[id][suffix] = value
          elsif suffix
            @triggered[id] = {nil => @triggered[id], suffix => value}
          else
            @triggered[id] = value
          end
        end
      end
    end

    def reset_triggered
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

    def unregister(object)
      @input_callbacks.unregister(object)
      @action_callbacks.unregister(object)
    end

    def with_triggered(ids_and_values)
      @input_callbacks.prepare_triggered(ids_and_values)
      @action_callbacks.prepare_triggered(ids_and_values)
      yield
    ensure
      @input_callbacks.reset_triggered
      @action_callbacks.reset_triggered
    end

  end # class Callbacks

end # module Wee
