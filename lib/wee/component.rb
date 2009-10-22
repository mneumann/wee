require 'wee/presenter'
require 'wee/decoration'
require 'wee/call_answer'

module Wee

  #
  # The base class of all components. You should at least overwrite method
  # #render in your own subclasses.
  #
  class Component < Presenter

    #
    # Initializes a newly created component.
    #
    # Call this method from your own components' <i>initialize</i> method using
    # +super+, before setting up anything else! 
    #
    def initialize() # :notnew:
      @decoration = self
    end

    #
    # This method renders the content of the component.
    #
    # *OVERWRITE* this method in your own component classes to implement the
    # view. By default this method does nothing!
    #
    # [+r+]
    #    An instance of class <tt>renderer_class()</tt>
    #
    def render(r)
    end

    #
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
    # By default only the decoration chain is backtracked. This is
    # required to correctly backtrack called components. To disable
    # backtracking of the decorations, change method
    # Component#backtrack_decoration to a no-operation:
    #
    #   def backtrack_decoration(state)
    #     # nothing here
    #   end
    #
    # [+state+]
    #    An object of class State
    #
    def backtrack(state)
      backtrack_decoration(state)
      for child in self.children
        child.decoration.backtrack(state)
      end
    end

    NO_CHILDREN = [].freeze
    #
    # Return all child components.
    #
    # *OVERWRITE* this method and return all child components
    # collected in an array.
    #
    def children
      return NO_CHILDREN
    end

    #
    # Process and invoke all callbacks specified for this component and all of
    # it's child components. 
    #
    def process_callbacks(callbacks)
      callbacks.input_callbacks.each_triggered(self) do |callback, value|
        callback.call(value)
      end

      # process callbacks of all children
      for child in self.children
        child.decoration.process_callbacks(callbacks)
      end

      callbacks.action_callbacks.each_triggered(self) do |callback, value|
        callback.call
        session.send_response(nil) # prematurely end callback processing
      end
    end

    protected

    def backtrack_decoration(state)
      state.add_ivar(self, :@decoration, @decoration)
    end

    include Wee::DecorationMixin
    include Wee::CallAnswerMixin

  end # class Component

end # module Wee
