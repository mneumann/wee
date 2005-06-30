class Wee::Presenter

  def renderer_class
    Wee::DefaultRenderer
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

  # Send a premature response. 

  protected

  def send_response(response)
    throw :wee_abort_callback_processing, response
  end

  # Call the block inside a rendering environment, then send the response prematurely.

  def send_render_response(&block)
    # Generate a response
    response = Wee::GenericResponse.new('text/html', '')

    # Get the current context we are in
    context = session.current_context

    # A rendering context is needed to use 'r' (if you want, you can simply
    # omit this and just return the response with some html/xml filled in.
    rendering_context = Wee::RenderingContext.new(
      context.request, 
      context.response, 
      session,
      session.current_callbacks, 
      Wee::HtmlWriter.new(response.content))

    with_renderer_for(rendering_context, &block)

    send_response(response)
  end


  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  # :section: Properties
  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  public

  def properties() @__properties end
  def properties=(props) @__properties = props end

  # Returns an "owned" property.

  def get_property(prop)
    if self.properties
      self.properties[prop]
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

  # This is currently only used for describing which properties are required by
  # the underlying component.

  def self.uses_property(*args)
  end

end
