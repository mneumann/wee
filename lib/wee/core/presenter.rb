# Wee::Presenter is the superclass of all classes that want to participate in
# rendering and callback-processing. Wee::Component and Wee::Decoration are
# it's two most important subclasses.

class Wee::Presenter

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  # :section: Render
  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  public

  # This method renders the content of the presenter with the given renderer.
  #
  # *OVERWRITE* this method in your own presenter classes to implement the
  # view.  By default this method does nothing!
  #
  # [+renderer+]
  #    A renderer object.

  def render_content_on(renderer)
  end

  # Render the presenter in the given rendering context. <b>DO NOT</b>
  # overwrite this method, unless you know exactly what you're doing!
  #
  # Creates a new renderer object of the class returned by method
  # #renderer_class, then invokes #render_content_on with the new
  # renderer.
  #
  # [+rendering_context+]
  #    An object of class RenderingContext

  def render(rendering_context)
    with_renderer_for(rendering_context) do |r| render_content_on(r) end 
  end

  protected

  # Creates a new renderer object of the class returned by method
  # #renderer_class, then yields it to the block and finally closes the
  # renderer.

  def with_renderer_for(rendering_context) 
    renderer = renderer_class.new(rendering_context)
    renderer.current_component = self
    begin
      yield renderer
    ensure
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
  # it calls the block if one was given (used by subclasses). Finally, all
  # action callbacks are invoked.
  #
  # [+callback_stream+]
  #    An object of class CallbackStream

  def process_callbacks(callback_stream) # :yields:

    # invoke input callbacks
    for callback in callback_stream.get_callbacks_for(self, :input)
      callback.invoke
    end

    # enable subclasses to add behaviour, e.g. a Component class will invoke
    # process_callback_chain for each child in the block.
    yield if block_given?

    # invoke action callbacks
    for callback in callback_stream.get_callbacks_for(self, :action)

      catch(:wee_back_to_process_callbacks) { callback.invoke }

      if cont = session.continuation_stack.pop
        cont.call
        raise "FATAL! Please inform the developer!"
      end

    end

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

end
