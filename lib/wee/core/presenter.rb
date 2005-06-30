# Wee::Presenter is the superclass of all classes that want to participate in
# rendering and callback-processing. Wee::Component and Wee::Decoration are
# it's two most important subclasses.

class Wee::Presenter

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  # :section: Render
  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  public

  # This method renders the content of the presenter.
  #
  # *OVERWRITE* this method in your own presenter classes to implement the
  # view. By default this method does nothing!
  #
  # Use the current renderer as returned by #renderer or it's short-cut #r.

  def render
  end

  # Render the presenter in the given rendering context. <b>DO NOT</b>
  # overwrite this method, unless you know exactly what you're doing!
  #
  # Creates a new renderer object of the class returned by method
  # #renderer_class, makes this the current renderer, then invokes method
  # #render.
  #
  # [+rendering_context+]
  #    An object of class RenderingContext

  def do_render(rendering_context)
    with_renderer_for(rendering_context) do render() end 
  end

  protected

  # Returns the current renderer object for use by the render methods.
  def renderer() @__renderer end

  # Short cut for #renderer.
  def r() @__renderer end

  # Creates a new renderer object of the class returned by method
  # #renderer_class, then makes this the current renderer for the time the
  # block it yields to executes. Finally, it restores the current renderer to
  # the former one and closes the newly created renderer. 

  def with_renderer_for(rendering_context) 
    old_renderer = @__renderer
    begin
      renderer_class.new(rendering_context, self) {|@__renderer| yield }
    ensure
      @__renderer = old_renderer
    end
  end

  # Returns the class used as renderer for this presenter. Overwrite this
  # method if you want to use a different renderer.
  #
  # Returned class must be a subclass of Wee::Renderer.
  # 
  # NEEDS TO BE OVERWRITTEN by some non-core files. 

  def renderer_class
    raise "Method renderer_class needs to be implemented!"
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  # :section: Callback
  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  public

  # Process all callbacks specified for this presenter. 
  #
  # [+block+]
  #    Specifies the action to be taken (e.g. whether to invoke input or action
  #    callbacks).

  def process_callbacks(&block)
    block.call(self)
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  # :section: Backtrack
  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  public

  # Dummy implementation. See Component#backtrack_state for more information. 
  #
  # [+snapshot+]
  #    An object of class Snapshot

  def backtrack_state(snapshot)
  end

end
