class Wee::ActionHandler
  attr_accessor :obj, :meth, :args

  def self.[](obj, meth, *args)
    new(obj, meth, *args)
  end

  def initialize(obj, meth, *args)
    @obj, @meth, @args = obj, meth.to_s, args
  end

  def invoke
    @obj.send(@meth, *@args)
  end
end

class Wee::ResourceHandler
  attr_accessor :content, :content_type
  def initialize(content, content_type) 
    @content, @content_type = content, content_type
  end
end

class Wee::HandlerRegistry
  def initialize
    @next_handler_id = 1
    @action_registry = Hash.new
    @input_registry = Hash.new
    @resource_registry = Hash.new 
  end

  def handler_id_for_action(action_handler)
    hid = get_next_handler_id() 
    raise if @action_registry.has_key?(hid)
    @action_registry[hid] = action_handler
    return hid
  end

  def handler_id_for_input(obj, input)
    hid = get_next_handler_id() 
    raise if @input_registry.has_key?(hid)
    @input_registry[hid] = [obj, input.to_s]
    return hid
  end

  def handler_id_for_resource(resource)
    hid = get_next_handler_id() 
    raise if @resource_registry.has_key?(hid)
    @resource_registry[hid] = resource
    return hid
  end

  def get_action(handler_id, obj) 
    action_handler = @action_registry[handler_id]
    return nil unless action_handler

    if action_handler.obj == obj
      action_handler 
    else
      nil
    end
  end

  def get_input(handler_id, obj) 
    return nil unless @input_registry.has_key?(handler_id)

    component, input = @input_registry[handler_id] 

    if component == obj
      input 
    else
      nil
    end
  end

  def get_resource(handler_id)
    return @resource_registry[handler_id]
  end

  private

  # TODO: randomize
  def get_next_handler_id
    @next_handler_id.to_s
  ensure
    @next_handler_id += 1
  end

end
