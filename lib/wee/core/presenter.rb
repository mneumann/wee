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
  def renderer() @renderer end

  # Short cut for #renderer.
  def r() @renderer end

  # Creates a new renderer object of the class returned by method
  # #renderer_class, then makes this the current renderer for the time the
  # block it yields to executes. Finally, it restores the current renderer to
  # the former one and closes the newly created renderer. 

  def with_renderer_for(rendering_context) 
    renderer = renderer_class.new(rendering_context)
    renderer.current_component = self
    old_renderer = @renderer 
    begin
      @renderer = renderer
      yield
    ensure
      @renderer = old_renderer
      renderer.close # write outstanding brushes to the document
    end
  end

  # Returns the class used as renderer for this presenter. Overwrite this
  # method if you want to use a different renderer.

  def renderer_class
    Wee::DefaultRenderer
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  # :section: Callback
  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  public

  # Process all callbacks specified for this presenter. 
  #
  # At first, this method invokes all input callbacks of this presenter, then
  # it calls the block if one was given (used by subclasses). Finally, the
  # action callback is invoked (there's only one per request).
  #
  # NOTE: Input callbacks should never call other components!
  #
  # [+callback_stream+]
  #    An object of class CallbackStream

  def process_callbacks(callback_stream) # :yields:
    # invoke input callbacks
    callback_stream.with_callbacks_for(self, :input) { |callback, value|
      callback.call(value)
    }

    # enable subclasses to add behaviour, e.g. a Component class will invoke
    # process_callbacks_chain for each child in the block.
    yield if block_given?

    # invoke action callback. only the first action callback is invoked.
    callback_stream.with_callbacks_for(self, :action) { |callback, value|
      callback.call
      throw :wee_back_to_session
    }
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

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  # :section: Session
  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  public

  # Returns the current session. A presenter (or component) has always an
  # associated session. The returned object is of class Wee::Session or a
  # subclass thereof.

  def session
    Wee::Session.current
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  # :section: Properties
  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  attr_accessor :properties

  # Returns an "owned" property.

  def get_property(prop)
    if @properties
      @properties[prop]
    else
      nil
    end
  end

  # Tries to lookup a property from different places. +nil+ as property value
  # is not allowed!
  # 
  # Search order:
  #
  # 1. self.get_property(prop) 
  #
  # 2. session.get_property(prop, self.class) 
  #
  # 3. application.get_property(prop, self.class)
  # 
  # 4. session.get_property(prop, nil) 
  #
  # 5. application.get_property(prop, nil) 
  #
  # 6. @@properties[prop] 
  # 

  def lookup_property(prop)
    val = get_property(prop)
    return val if val != nil

    sess = session()
    app = sess.application
    klass = self.class

    val = sess.get_property(prop, klass)
    return val if val != nil

    val = app.get_property(prop, klass)
    return val if val != nil

    val = sess.get_property(prop, nil)
    return val if val != nil

    val = app.get_property(prop, nil)
    return val if val != nil

    if defined?(@@properties)
      val = @@properties[prop]
      return val if val != nil
    end

    return nil
  end

end
