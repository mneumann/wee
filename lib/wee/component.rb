class Wee::Component

  attr_accessor :caller # who is calling us

  # call another component
  CallUsesContinuation = Object.new
  def call(component, return_method=CallUsesContinuation)
    if return_method == CallUsesContinuation
      callcc {|cc|
        component.caller = [self, cc]
        add_decoration(Wee::Delegate.new(component))
        throw :back_to_process_request_actions
      }
    else
      component.caller = [self, return_method]
      add_decoration(Wee::Delegate.new(component))
    end
  end

  # return from a called component
  def answer(*args)
    component, return_method = self.caller
    component.remove_first_decoration
    self.caller = nil

    case return_method
    when Continuation
      return_method.call(*args)
    when nil
      # nothing
    else
      component.send(return_method, *args)
    end 
  end

  def process_request(context)
    process_request_inputs(context)
    children.each {|c| c.decoration.process_request(context) }
    process_request_actions(context)
  end

  def process_request_inputs(context)
    context.request.query.each do |hid, value|
      if act = context.handler_registry.get_input(hid, self)
        send(act, value) 
      end
    end
  end

  def process_request_actions(context)
    was_cc = [false]    # did we return from a continuation call or not?

    # handle URL actions
    if act = context.handler_registry.get_action(context.handler_id, self)
      was_cc[0] = true if catch(:back_to_process_request_actions) { act.invoke; true }.nil?
    end

    # handle form actions
    context.request.query.each do |hid, value|
      if act = context.handler_registry.get_action(hid, self)
        was_cc[0] = true if catch(:back_to_process_request_actions) { act.invoke; true }.nil?
      end
    end

    throw :back_to_request_response_loop if was_cc[0]
  end

  # Creates a new renderer for this component and renders it.
  def render_with_context(rendering_context)
    r = renderer_class.new(rendering_context)
    r.current_component = self
    render_content_on(r)
  end

  # You call render_on to render a component.
  def render_on(renderer)
    decoration.render_with_context(renderer.context)
  end

  def render_content_on(r)
  end

  def renderer_class
    Wee::HtmlCanvas
  end

  def children
    @children || []
  end

  def add_child(c)
    @children ||= []
    @children << c
  end

  def add_children(*c)
    @children ||= []
    @children.push(*c)
  end

  # returns the first decoration in the decoration chain, or the component
  # itself, if none was specified

  attr_writer :decoration

  # FIXME: @decoration may never be self when backtracking
  # in any case, self==nil
  def decoration
    @decoration || self
  end

  # add decoration _d_ in front of the decoration chain.
  def add_decoration_in_front(d)
    d.next = self.decoration
    self.decoration = d 
  end
  alias add_decoration add_decoration_in_front

  def remove_decoration(d)
    if d == @decoration
      # d is in front
      @decoration = d.next
    else
      last_decoration = @decoration
      loop do
        raise "not found" if last_decoration == self 
        break if d == last_decoration.next
        last_decoration = last_decoration.next
      end
      last_decoration.next = d.next  
    end
  end

  def add_decoration(d)
    d.next = self.decoration
    self.decoration = d 
  end

  def remove_first_decoration
    self.decoration = self.decoration.next
    self.decoration = nil if self.decoration == self
  end

  def session
    Wee::Session.current
  end

end
