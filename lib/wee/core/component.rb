# The base class of all components. You should at least overwrite method
# #render_content_on in your own subclasses.

class Wee::Component < Wee::Presenter

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  # :section: Render
  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  public

  # Starts rendering the decoration chain by calling method Presenter#render
  # for the first decoration of the component, or calling <i>render</i> for the
  # component itself if no decorations were specified. 
  # 
  # [+rendering_context+]
  #    An object of class RenderingContext

  def render_chain(rendering_context)
    decoration.render(rendering_context)
  end

  # This method renders the content of this component with the given renderer.
  #
  # *OVERWRITE* this method in your own component class to implement the
  # view. By default this method does nothing!
  #
  # [+renderer+]
  #    A renderer object.

  def render_content_on(renderer)
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  # :section: Callback
  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  public

  # Starts processing the callbacks for the decoration chain by invoking method
  # #process_callbacks of the first decoration or the component itself if no
  # decorations were specified.
  #
  # [+callback_stream+]
  #    An object of class CallbackStream

  def process_callback_chain(callback_stream)
    decoration.process_callbacks(callback_stream)
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

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  # :section: Init
  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  protected

  # Initializes a newly created component.
  #
  # Call this method from your own components' <i>initialize</i> method using
  # +super+, before setting up anything else! 

  def initialize() # :notnew:
    @decoration = Wee::ValueHolder.new(self)
    @children = []
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  # :section: Children
  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  protected

  # Returns all direct child components collected in an array.
 
  def children
    @children
  end

  # Add a child to the component. Example:
  # 
  #   class YourComponent < Wee::Component
  #     def initialize
  #       super()
  #       add_child ChildComponent.new
  #     end
  #   end
  #
  # If you dynamically add child components to a component at run-time (not in
  # initialize), then you should consider to backtrack the children array (of
  # course only if you want backtracking at all): 
  #   
  #   def backtrack_state(snapshot)
  #     super
  #     snapshot.add(self.children)
  #   end
  #

  def add_child(child)
    self.children << child
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  # :section: Decoration
  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  public

  # Returns the first decoration from the component's decoration chain, or
  # +self+ if no decorations were specified for the component.

  def decoration
    @decoration.value
  end

  # Set the pointer to the first decoration to +d+. 

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

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  # :section: Backtrack
  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  public

  # Starts the backtrack-state phase for the decoration chain, by invoking
  # method #backtrack_state of the first decoration or the component itself if
  # no decorations were specified. 
  # 
  # See #backtrack_state for details.
  #
  # [+snapshot+]
  #    An object of class Snapshot

  def backtrack_state_chain(snapshot)
    decoration.backtrack_state(snapshot)
  end

  # Take snapshots of objects that should correctly be backtracked.
  #
  # Backtracking means that you can go back in time of the components' state.
  # Therefore it is neccessary to take snapshots of those objects that want to
  # participate in backtracking. Taking snapshots of the whole component tree
  # would be too expensive and unflexible. Note that methods
  # <i>take_snapshot</i> and <i>restore_snapshot</i> are called for those
  # objects to take the snapshot (they behave like <i>marshal_dump</i> and
  # <i>marshal_load</i>). Overwrite them if you want to define special
  # behaviour. 
  #
  # By default only <tt>@decoration</tt> is backtracked (which actually is a
  # ValueHolder, as only the pointer changes not the decoration-object
  # itself!).
  #
  # For example if you dynamically add children to your component, you might
  # want to backtrack the children array. Therefore you simply pass it to the
  # Snapshot#add method:
  #
  #   def backtrack_state(snapshot)
  #     super
  #     snapshot.add(self.children)
  #   end
  #
  # This will call Array#take_snapshot to take the snapshot for the children
  # array. If at a later point in time a snapshot is restored,
  # Array#restore_snapshot will be called with the return value of
  # Array#take_snapshot as argument.
  #
  # [+snapshot+]
  #    An object of class Snapshot

  def backtrack_state(snapshot)
    snapshot.add(@decoration)
    children.each do |child| child.backtrack_state_chain(snapshot) end
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  # :section: Call/Answer
  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  protected

  # Call another component. The calling component is neither rendered nor are
  # it's callbacks processed until the called component answers using method
  # #answer. 
  #
  # [+component+]
  #   The component to be called.
  #
  # <b>How it works</b>
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

  def call(component)
    add_decoration(delegate = Wee::Delegate.new(component))
    component.add_decoration(answer = Wee::AnswerDecoration.new)

    result = callcc {|cc|
      answer.on_answer = cc
      throw :wee_back_to_process_callbacks
    }

    remove_decoration(delegate)
    component.remove_decoration(answer)
    #answer.on_answer = nil  # TODO: is this a memory leak?

    return result
  end

  # Return from a called component.
  #
  # After answering, the component that calls #answer should no further be
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

end
