module Wee

  #
  # Presenter is the superclass of all classes that want to participate in
  # rendering and callback-processing. It merely specifies an interface without
  # actual implementation. 
  #
  # Class Component and Decoration are it's two most important subclasses.
  # 
  class Presenter

    def render_on(context); raise end
    def backtrack(state); raise end
    def process_callbacks(callbacks); raise end

    protected

    # Returns the class used as renderer for this presenter. Overwrite this
    # method if you want to use a different renderer.
    #
    # Returned class must be a subclass of Wee::Renderer.

    def renderer_class
      Wee::DefaultRenderer
    end

  end # class Presenter

end # module Wee
