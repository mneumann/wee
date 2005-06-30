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
  # [+block+]
  #    Specifies the action to be taken (e.g. whether to invoke input or action
  #    callbacks).

  def process_callbacks_chain(&block)
    decoration.process_callbacks(&block)
  end

  # Process and invoke all callbacks specified for this component and all of
  # it's child components. 
  #
  # [+block+]
  #    Specifies the action to be taken (e.g. whether to invoke input or action
  #    callbacks).

  def process_callbacks(&block)
    block.call(self)

    # process callbacks of all children
    children.each do |child|
      child.process_callbacks_chain(&block)
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
    @__decoration = Wee::ValueHolder.new(self)
    @__children = []
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  # :section: Children/Composite
  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  protected

  # Returns all direct child components collected in an array.
  # 
  # You can overwrite this method to return all direct child components of this
  # component.
 
  def children
    @__children
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
    child
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  # :section: Decoration
  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  public

  # Returns the first decoration from the component's decoration chain, or
  # +self+ if no decorations were specified for the component.

  def decoration
    @__decoration.value
  end

  # Set the pointer to the first decoration to +d+. 

  def decoration=(d) 
    @__decoration.value = d
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
  #
  # Returns: +self+

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

    return self
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
  # By default only <tt>@__decoration</tt> is backtracked (which actually is a
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
    snapshot.add(@__decoration)
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
  # [+return_callback+]
  #   Is invoked when the called component answers.
  #   Either a symbol or any object that responds to #call. If it's a symbol,
  #   then the corresponding method of the current component will be called.
  #
  # [+args+]
  #   Arguments that are passed to the +return_callback+ before the 'onanswer'
  #   arguments.
  #
  # <b>How it works</b>
  # 
  # The component to be called is wrapped with an AnswerDecoration and the
  # +return_callback+ parameter is assigned to it's +on_answer+ attribute (not
  # directly as there are cleanup actions to be taken before the
  # +return_callback+ can be invoked, hence we wrap it in the OnAnswer class).
  # Then a Delegate decoration is added to the calling component (self), which
  # delegates to the component to be called (+component+). 
  #
  # Then we unwind the calling stack back to the Session by throwing
  # <i>:wee_abort_callback_processing</i>. This means, that there is only ever
  # one action callback invoked per request. This is not neccessary, we could
  # simply omit this, but then we'd break compatibility with the implementation
  # using continuations.
  #
  # When at a later point in time the called component invokes #answer, this
  # will throw a <i>:wee_answer</i> exception which is catched in the
  # AnswerDecoration. The AnswerDecoration then invokes the +on_answer+
  # callback which cleans up the decorations we added during #call, and finally
  # passes control to the +return_callback+. 
  #

  def call(component, return_callback=nil, *args)
    add_decoration(delegate = Wee::Delegate.new(component))
    component.add_decoration(answer = Wee::AnswerDecoration.new)
    answer.on_answer = OnAnswer.new(self, component, delegate, answer, 
                                    return_callback, args)
    throw :wee_abort_callback_processing, nil 
  end

  class OnAnswer < Struct.new(:calling_component, :called_component, :delegate, 
                              :answer, :return_callback, :args)

    def call(*answer_args)
      calling_component.remove_decoration(delegate)
      called_component.remove_decoration(answer)
      return if return_callback.nil?
      if return_callback.respond_to?(:call)
        return_callback.call(*(args + answer_args))
      else
        calling_component.send(return_callback, *(args + answer_args))
      end
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
