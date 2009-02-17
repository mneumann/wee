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
    def backtrack_state(snapshot); raise end
    def process_callbacks(callbacks); raise end

  end # class Presenter

end # module Wee
