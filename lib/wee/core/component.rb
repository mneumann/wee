# The base class of all components. You should at least overwrite method
# #render in your own subclasses.

class Wee::Component < Wee::Presenter

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  # :section: Render
  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  public

  # Starts rendering the decoration chain by calling method Presenter#do_render
  # for the first decoration of the component, or calling <i>do_render</i> for
  # the component itself if no decorations were specified. 
  # 
  # [+rendering_context+]
  #    An object of class RenderingContext

  def do_render_chain(rendering_context)
    decoration.do_render(rendering_context)
  end

  # This method renders the content of this component.
  #
  # *OVERWRITE* this method in your own component class to implement the
  # view. By default this method does nothing!
  #
  # Use the current renderer as returned by #renderer or it's short-cut #r.

  def render
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

  def process_callbacks_chain(callback_stream)
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
        child.process_callbacks_chain(callback_stream)
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

  # Iterates over all decorations (note that the component itself is excluded). 

  def each_decoration # :yields: decoration
    d = self.decoration
    loop do
      break if d == self or d.nil?
      yield d
      d = d.owner
    end
  end
  
  # Adds decoration +d+ to the decoration chain.
  #
  # A global decoration is added in front of the decoration chain, a local
  # decoration is added in front of all other local decorations but after all
  # global decorations.

  def add_decoration(d)
    if d.global?
      d.owner = self.decoration
      self.decoration = d
    else
      last_global = nil
      each_decoration {|i| 
        if i.global?
          last_global = i
        else
          break
        end
      }
      if last_global.nil?
        # no global decorations specified -> add in front
        d.owner = self.decoration
        self.decoration = d
      else
        # add after last_global
        d.owner = last_global.owner
        last_global.owner = d 
      end
    end
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

  # Remove all decorations that match the block condition.
  # 
  # Example (removes all decorations of class +HaloDecoration+):
  # 
  #   remove_decoration_if {|d| d.class == HaloDecoration}
  #

  def remove_decoration_if # :yields: decoration
    to_remove = []
    each_decoration {|d| to_remove << d if yield d}
    to_remove.each {|d| remove_decoration(d)}
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
  # (+component+). Then we unwind the calling stack back to the Session by
  # throwing <i>:wee_back_to_session</i>. This means, that there is only ever
  # one action callback invoked per request.  When at a later point in time the
  # called component invokes #answer, this will throw a <i>:wee_answer</i>
  # exception which is catched in the AnswerDecoration.  The AnswerDecoration
  # then jumps back to the continuation we created at the beginning, and
  # finally method #call returns. 
  #
  # Note that #call returns to an "old" stack-frame from a previous request.
  # That is why we throw <i>:wee_back_to_session</i> after invoking an action
  # callback, and that's why only ever one is invoked. We could remove this
  # limitation without problems, but then there would be a difference between
  # those action callbacks that call other components and those that do not.  

  def call(component, return_callback=:use_continuation)
    add_decoration(delegate = Wee::Delegate.new(component))
    component.add_decoration(answer = Wee::AnswerDecoration.new)

    if return_callback == :use_continuation
      result = callcc {|cc|
        answer.on_answer = cc
        throw :wee_back_to_session
      }
      remove_decoration(delegate)
      component.remove_decoration(answer)
      return result
    else
      # TODO: make this marshallable! 
      answer.on_answer = proc {|*args|
        remove_decoration(delegate)
        component.remove_decoration(answer)
        return_callback.call(*args)
      }
      throw :wee_back_to_session
    end
  end

  # Return from a called component.
  # 
  # NOTE that #answer never returns.
  #
  # See #call for a detailed description of the call/answer mechanism.

  def answer(*args)
    throw :wee_answer, args 
  end

end
