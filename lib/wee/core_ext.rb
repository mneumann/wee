module Wee
  class AbortCallbackProcessing < Exception
    attr_reader :response
    def initialize(response)
      super()
      @response = response
    end
  end
end

class Wee::Presenter

  public

  # Returns the current session. A presenter (or component) has always an
  # associated session. The returned object is of class Wee::Session or a
  # subclass thereof.

  def session
    Wee::Session.current
  end

  # Send a premature response. 

  protected


  def send_response(response)
    raise Wee::AbortCallbackProcessing.new(response)
  end

  # Call the block inside a rendering environment, then send the response prematurely.

  def send_render_response(&block)
    # Generate a response
    response = Wee::GenericResponse.new

    # Get the current context we are in
    context = session.current_context
    context.callbacks = session.current_callbacks
    context.document = Wee::HtmlWriter.new(response)

    block.call(renderer_class.new(context, self))

    send_response(response)
  end

end
