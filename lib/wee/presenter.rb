module Wee

  # Wee::Presenter is the superclass of all classes that want to participate in
  # rendering and callback-processing. Wee::Component and Wee::Decoration are
  # it's two most important subclasses.

  class Presenter

    # This method renders the content of the presenter.
    #
    # *OVERWRITE* this method in your own presenter classes to implement the
    # view. By default this method does nothing!
    #
    # Use the current renderer as returned by #renderer or it's short-cut #r.

    def render(r)
    end

    # Render the presenter in the given rendering context. <b>DO NOT</b>
    # overwrite this method, unless you know exactly what you're doing!
    #
    # Creates a new renderer object of the class returned by method
    # #renderer_class, makes this the current renderer, then invokes method
    # #render.
    #
    # [+context+]
    #    An object of class Context

    def render_on(context)
      render(renderer_class.new(context, self))
    end

    # Dummy implementation. See Component#backtrack_state for more information. 
    #
    # [+snapshot+]
    #    An object of class Snapshot

    def backtrack_state(snapshot)
    end

    def process_callbacks(callbacks)
      callbacks.input_callbacks.each_triggered(self) do |callback, value|
        callback.call(value)
      end

      callbacks.action_callbacks.each_triggered(self) do |callback, value|
        callback.call
        # TODO: return to main loop
      end
    end

    protected

    # Returns the class used as renderer for this presenter. Overwrite this
    # method if you want to use a different renderer.
    #
    # Returned class must be a subclass of Wee::Renderer.
    # 
    # NEEDS TO BE OVERWRITTEN by some non-core files. 

    def renderer_class
      raise "Method renderer_class needs to be implemented!"
    end

  end # class Presenter

end # module Wee
