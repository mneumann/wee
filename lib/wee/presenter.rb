# Wee::Presenter is the superclass of all classes that want to participate in
# rendering and callback-processing. Wee::Component and Wee::Decoration are
# it's two most important subclasses.

class Wee::Presenter

  # This method renders the content of the presenter with the given renderer.
  #
  # OVERWRITE this method in your own presenter classes to implement the view.
  # By default this method does nothing!
  #
  # [+renderer+]
  #    A renderer object.

  def render_content_on(renderer)
  end

  # Render the presenter in the given rendering context. DO NOT overwrite this
  # method, unless you know exactly what you're doing!
  #
  # Creates a new renderer object of the class returned by method
  # <i>renderer_class</i>, then invokes render_content_on with the new
  # renderer.
  #
  # [+rendering_context+]
  #    An object of class RenderingContext

  def render(rendering_context)
    r = renderer_class.new(rendering_context)
    r.current_component = self
    render_content_on(r)
    r.close # write outstanding brushes to the document
  end

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
        raise "FATAL"
      end

    end

  end

  protected

  # Returns the class used as renderer for this presenter. Overwrite this
  # method if you want to use a different renderer.

  def renderer_class
    Wee::HtmlCanvas
  end

  # Returns the current session. A presenter (or component) has always an
  # associated session. The returned object is of class Wee::Session or a
  # subclass thereof.

  def session
    Wee::Session.current
  end

end
