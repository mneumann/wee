# The base class of all components. You should at least overwrite method
# <i>render_content_on</i> (see Presenter#render_content_on) in your own
# subclasses.

class Wee::Component < Wee::Presenter

  # Starts rendering the decoration chain by calling method <i>render</i> for
  # the first decoration of the component, or calling <i>render</i> for the
  # component itself if no decorations were specified. 
  # 
  # [+rendering_context+]
  #    An object of class RenderingContext

  def render_chain(rendering_context)
    decoration().render(rendering_context)
  end

  # Starts processing the callbacks for the decoration chain by invoking method
  # <i>Presenter#process_callbacks</i> of the first decoration or the component
  # itself if no decorations were specified.
  #
  # [+callback_stream+]
  #    An object of class CallbackStream

  def process_callback_chain(callback_stream)
    decoration().process_callbacks(callback_stream)
  end

  # Process and invoke all callbacks specified for this component and all of
  # it's child components. 
  #
  # All input callbacks of this component and it's child components are
  # processed/invoked before any of the action callbacks are processed/invoked.
  #
  # [+callback_stream+]
  #    An object of class CallbackStream

  def process_callbacks(callback_stream)
    super do
      # process callbacks of all children
      children.each do |child|
        child.process_callback_chain(callback_stream)
      end
    end
  end

  protected

  # Initializes a newly created component.
  #
  # Call this method from your own components' <i>initialize</i> method using
  # +super+, before setting up anything else. 
  #
  # By default neither <tt>@decoration</tt> nor <tt>@children</tt> are
  # registered for being backtracked. If your component calls other components,
  # and if you want to be able to use the browsers back-button, then your
  # <i>initialize</i> method should look like this one: 
  #
  #   def initialize
  #     super()      # calls Component#initialize
  #     session.register_object_for_backtracking(@decoration)
  #     ...
  #   end

  def initialize() # :notnew:
    @decoration = Wee::ValueHolder.new(self)
    @children = []
  end

  # Returns all direct child components collected in an array.
  # 
  # Either overwrite this method to return the child components of your
  # component, or just append the child components to the returned array
  # (prefered way):   
  #
  #   class YourComponent < Wee::Component
  #     def initialize
  #       super
  #       children << ChildComponent.new
  #     end
  #   end
  #
  # If you dynamically append child components to this array at run-time (not
  # in initialize), then you should register <tt>@children</tt> for being 
  # backtracked (of course only if you want backtracking at all): 
  #   
  #   def initialize
  #     super
  #     session.register_object_for_backtracing(@children)
  #   end
 
  def children
    @children
  end

  # Returns the current session. A component has always an associated session.
  # The returned object is of class Wee::Session or a subclass thereof.

  def session
    Wee::Session.current
  end

  # Call another component. The calling component is neither rendered nor are
  # it's callbacks processed until the called component answers using method
  # _answer_. 
  #
  # [+component+]
  #   The component to be called.
  #
  # [+return_method+]
  #    If the called component returns, call this method of the calling
  #    component with the arguments passed to method _answer_. If nil, no
  #    method will be called.

  def call(component, return_method=nil)
    answer = Wee::AnswerDecoration.new(self, component)
    answer.return_method = return_method 
    add_decoration(answer)
    nil
  end

  # Return from a called component.
  #
  # After answering, the component that calls _answer_ should no further be
  # used or reused.

  def answer(*args)
    throw :wee_answer_call, args 
  end

  # -----------------------------------------------------------------------------
  # Decorations
  # -----------------------------------------------------------------------------

  public

  # Returns the first decoration from the component's decoration chain, or
  # +self+ if no decorations were specified for the component.
  #
  # DO NOT use <tt>@decoration</tt> directly, as it's a ValueHolder!

  def decoration() @decoration.value end

  # Set the pointer to the first decoration to +d+. 
  #
  # DO NOT use <tt>@decoration</tt> directly, as it's a ValueHolder!

  def decoration=(d) 
    @decoration.value = d
  end

  # Adds decoration +d+ in front of the decoration chain.

  def add_decoration(d)
    d.owner = self.decoration
    self.decoration = d
  end

  # Remove decoration +d+ from the decoration chain. 
  # 
  # Returns the removed decoration or +nil+ if it did not exist in the
  # decoration chain.

  def remove_decoration(d)
    if d == self.decoration  # 'd' is in front
      self.decoration = d.owner
    else
      last_decoration = self.decoration
      next_decoration = nil
      loop do
        return nil if last_decoration == self or last_decoration.nil?
        next_decoration = last_decoration.owner
        break if d == next_decoration
        last_decoration = next_decoration
      end
      last_decoration.owner = d.owner  
    end
    return d
  end

end
