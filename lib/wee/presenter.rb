module Wee

  #
  # Presenter is the superclass of all classes that want to participate in
  # rendering and callback-processing. It merely specifies an interface without
  # actual implementation. 
  #
  # Class Component and Decoration are it's two most important subclasses.
  # 
  class Presenter

    def render!(r)
	#begin
      r.with(self) {|new_r| render(new_r)}
	#
    end

    def render(r); raise end
    def state(s); raise end

    def process_callbacks(callbacks); raise end

    #
    # Returns the class used as Renderer for this presenter. Overwrite this
    # method if you want to use a different Renderer than the default one.
    #
    # Returned class must be a subclass of Wee::Renderer.
    #
    def renderer_class
      Wee::HtmlCanvas
    end

    protected

    #
    # Returns the current session. A presenter (or component) has always an
    # associated session. The returned object is of class Wee::Session or a
    # subclass thereof.
    #
    def session
      Wee::Session.current
    end

  end # class Presenter

end # module Wee
