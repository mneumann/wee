require 'wee/presenter'
require 'wee/decoration'
require 'wee/call_answer'

module Wee

  #
  # The base class of all components. You should at least overwrite method
  # #render in your own subclasses.
  #
  class Component < Presenter

    # This method renders the content of the component.
    #
    # *OVERWRITE* this method in your own component classes to implement the
    # view. By default this method does nothing!

    def render(r)
    end

    # Renders the component in the given rendering context. <b>DO NOT</b>
    # overwrite this method, unless you know exactly what you're doing!
    #
    # Creates a new renderer object of the class returned by method
    # #renderer_class, makes this the current renderer, then invokes method
    # #render.
    #
    # [+context+]
    #    An object of class Context

    def render_on(context)
      render(renderer_class.new(context, self))
    end

    protected

    # Returns the class used as renderer for this component. Overwrite this
    # method if you want to use a different renderer.
    #
    # Returned class must be a subclass of Wee::Renderer.

    def renderer_class
      raise "Method renderer_class needs to be implemented!"
    end

    public

    # Process and invoke all callbacks specified for this component and all of
    # it's child components. 

    def process_callbacks(callbacks)
      callbacks.input_callbacks.each_triggered(self) do |callback, value|
        callback.call(value)
      end

      # process callbacks of all children
      each_child do |child|
        child.decoration.process_callbacks(callbacks)
      end

      callbacks.action_callbacks.each_triggered(self) do |callback, value|
        callback.call
        # TODO: return to main loop
      end
    end

    protected

    # Initializes a newly created component.
    #
    # Call this method from your own components' <i>initialize</i> method using
    # +super+, before setting up anything else! 

    def initialize() # :notnew:
      @decoration = self
      @children = nil
    end

    protected

    #
    # Iterates over all direct child components. 
    #
    def each_child(&block)
      @children.each(&block) if @children
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
    #   def backtrack(state)
    #     super
    #     state.add(self.children)
    #   end
    #

    def add_child(child)
      (@children ||= []) << child
      child
    end

    include Wee::DecorationMixin
    include Wee::CallAnswerMixin

    public

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
    # For example if you dynamically add children to your component, you might
    # want to backtrack the children array: 
    #
    #   def backtrack(state)
    #     super
    #     backtrack_children(state)
    #   end
    #
    # Or, those components that dynamically add decorations or make use of the 
    # call/answer mechanism should backtrack decorations as well: 
    #
    #   def backtrack(state)
    #     super
    #     backtrack_children(state)
    #     backtrack_decoration(state)
    #   end
    #
    # [+state+]
    #    An object of class State

    def backtrack(state)
      each_child do |child|
        child.decoration.backtrack(state)
      end
    end

    def backtrack_decoration(state)
      state.add_ivar(self, :@decoration, @decoration)
    end

    def backtrack_children(state)
      state.add_ivar(self, :@children, (@children and @children.dup))
    end


  end # class Component

end # module Wee
