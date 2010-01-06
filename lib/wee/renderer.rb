module Wee

  #
  # Base class of all Renderer classes.
  #
  class Renderer
    attr_accessor :session
    attr_accessor :request
    attr_accessor :response
    attr_accessor :callbacks
    attr_accessor :document
    attr_accessor :current_component

    def initialize(session=nil, request=nil, response=nil, callbacks=nil, document=nil, current_component=nil)
      @session = session
      @request = request
      @response = response
      @callbacks = callbacks
      @document = document
      @current_component = current_component
    end

    def with(component)
      rclass = component.renderer_class
      if rclass == self
        # reuse renderer
        old_component = @current_component 
        begin
          @current_component = component
          yield self
        ensure
          @current_component = old_component
        end
      else
        close
        r = rclass.new(@session, @request, @response, @callbacks, @document, component)
        begin
          yield r
        ensure
          r.close
        end
      end
    end

    #
    # NOTE: unregister will do nothing for a regular request, only
    # for an AJAX request. Only if you would render one and the
    # same component twice it would behave differently.
    #
    def render(component)
      close
      self.callbacks.unregister(component)
      component.decoration.render!(self)
      nil
    end

    def render_decoration(decoration)
      close
      self.callbacks.unregister(decoration)
      decoration.render!(self)
      nil
    end

    #
    # Subclass responsibility.
    #
    def close
    end

  end # class Renderer

end # module Wee
