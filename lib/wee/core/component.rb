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
  # +super+, before setting up anything else! 
  #
  # By default, only <tt>@decoration</tt> is registered for being backtracked,
  # but not <tt>@children</tt>. If you want to register your own objects for
  # being backtracked, i.e. being able to use the browsers back-button
  # correctly, then your <i>initialize</i> method should look like this one: 
  #
  #   def initialize
  #     super()      # calls Component#initialize
  #     session.register_object_for_backtracking(your_object)
  #     ...
  #   end

  def initialize() # :notnew:
    @decoration = Wee::StateHolder.new(self)
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
  #     super()
  #     session.register_object_for_backtracking(@children)
  #   end
 
  def children
    @children
  end

  # Call another component. The calling component is neither rendered nor are
  # it's callbacks processed until the called component answers using method
  # #answer. 
  #
  # === How it works
  # 
  # At first a continuation is created. The component to be called is then
  # wrapped with an AnswerDecoration and the continuation is assigned to it's
  # +on_answer+ attribute. Then a Delegate decoration is added to the calling
  # component (self), which delegates to the component to be called
  # (+component+). Then we unwind the calling stack back to
  # Presenter#process_callbacks by throwing
  # <i>:wee_back_to_process_callbacks</i>.  When at a later point in time the
  # called component invokes #answer, this will throw a <i>:wee_answer</i> exception
  # which is catched in the AnswerDecoration.  The AnswerDecoration then jumps
  # back to the continuation we created at the beginning, and finally method
  # #call returns. 
  #
  # Note that #call returns to an "old" stack-frame from a previous request.
  # Therefore, method #answer creates another continuation and pushes this onto
  # the sessions +continuation_stack+. In Presenter#process_callbacks we try to
  # pop from this stack every time after invoking a callback, and if there was
  # a continuation on the stack, we jump to it (and never return). This then
  # jumps back to the #answer method and returns to the current
  # Presenter#process_callbacks method, quite after the invokation of the
  # callback that caused method #answer to be called. From thereon, everything
  # proceeds as usual.
  #
  # This complicated procedure allows multiple action callbacks to be followed
  # in the same request and even multiple answer's.
  #
  # [+component+]
  #   The component to be called.
  #

  def call(component)
    delegate = Wee::Delegate.new(component)
    answer = Wee::AnswerDecoration.new
    component.add_decoration(answer)
    add_decoration(delegate)

    result = callcc {|cc|
      answer.on_answer = cc
      throw :wee_back_to_process_callbacks
    }

    remove_decoration(delegate)
    component.remove_decoration(answer)
    answer.on_answer = nil

    return result
  end

  # Return from a called component.
  #
  # After answering, the component that calls _answer_ should no further be
  # used or reused.
  #
  # See #call for a detailed description of the call/answer mechanism.

  def answer(*args)
    callcc {|cc|
      session.continuation_stack.push cc 
      throw :wee_answer, args 
    }
    throw :wee_back_to_process_callbacks
  end

  # :section: Decoration-related methods

  public

  # Returns the first decoration from the component's decoration chain, or
  # +self+ if no decorations were specified for the component.
  #
  # DO NOT use <tt>@decoration</tt> directly, as it's a StateHolder!

  def decoration
    @decoration.value
  end

  # Set the pointer to the first decoration to +d+. 
  #
  # DO NOT use <tt>@decoration</tt> directly, as it's a StateHolder!

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
    d.owner = nil  # decoration 'd' no longer is an owner of anything!
    return d
  end

end
