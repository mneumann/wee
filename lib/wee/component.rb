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
    # Constructs a new instance of the component.
    #
    # Overwrite this method when you want to use it both as a root component
    # and as a non-root component. Here you can add neccessary decorations
    # when used as root component, as for example a PageDecoration or a
    # FormDecoration. 
    #
    # By default this methods adds no decoration.
    #
    # See also class RootComponent.
    #
    def self.instanciate(*args, &block)
      new(*args, &block)
    end

    #
    # Return an array of classes onto which the current component depends. 
    # Right now this is only used to determine the required ExternalResources.
    #
    def self.depends
      []
    end

    #
    # Initializes a newly created component.
    #
    def initialize
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
    # Component#state_decoration to a no-operation:
    #
    #   def state_decoration(s)
    #     # nothing here
    #   end
    #
    # [+s+]
    #    An object of class State
    #
    def state(s)
      state_decoration(s)
      for child in self.children
        child.decoration.state(s)
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
    # Process and invoke all input callbacks specified for this component 
    # and all of it's child components.
    #
    # Returns the action callback to be invoked.
    #
    def process_callbacks(callbacks)
      callbacks.input_callbacks.each_triggered_call_with_value(self)

      action_callback = nil

      # process callbacks of all children
      for child in self.children
        if act = child.decoration.process_callbacks(callbacks)
          raise "Duplicate action callback" if action_callback
          action_callback = act
        end
      end

      if act = callbacks.action_callbacks.first_triggered(self)
        raise "Duplicate action callback" if action_callback
        action_callback = act
      end

      return action_callback
    end

    protected

    def state_decoration(s)
      s.add_ivar(self, :@decoration, @decoration)
    end

    # -------------------------------------------------------------
    # Decoration Methods
    # -------------------------------------------------------------

    def decoration=(d) @decoration = d end
    def decoration() @decoration || self end 

    #
    # Iterates over all decorations
    # (note that the component itself is excluded)
    #
    def each_decoration # :yields: decoration
      d = @decoration
      while d and d != self
        yield d
        d = d.next
      end
    end

    # 
    # Searches a decoration in the decoration chain
    #
    def find_decoration
       each_decoration {|d| yield d and return d }
       return nil
    end
 
    #
    # Adds decoration +d+ to the decoration chain.
    #
    # A global decoration is added in front of the decoration chain, a local
    # decoration is added in front of all other local decorations but after all
    # global decorations.
    #
    # Returns: +self+
    #
    def add_decoration(d)
      if d.global?
        d.next = self.decoration
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
          d.next = self.decoration
          self.decoration = d
        else
          # add after last_global
          d.next = last_global.next
          last_global.next = d
        end
      end

      return self
    end

    #
    # Remove decoration +d+ from the decoration chain. 
    # 
    # Returns the removed decoration or +nil+ if it did not exist in the
    # decoration chain.
    #
    def remove_decoration(d)
      if d == self.decoration  # 'd' is in front
        self.decoration = d.next
      else
        last_decoration = self.decoration
        next_decoration = nil
        loop do
          return nil if last_decoration == self or last_decoration.nil?
          next_decoration = last_decoration.next
          break if d == next_decoration
          last_decoration = next_decoration
        end
        last_decoration.next = d.next
      end
      d.next = nil  # decoration 'd' no longer is an owner of anything!
      return d
    end

    #
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

    # -------------------------------------------------------------
    # Call/Answer Methods
    # -------------------------------------------------------------

    #
    # Call another component (without using continuations). The calling
    # component is neither rendered nor are it's callbacks processed
    # until the called component answers using method #answer. 
    #
    # [+component+]
    #   The component to be called.
    #
    # [+return_callback+]
    #   Is invoked when the called component answers.
    #
    # <b>How it works</b>
    # 
    # The component to be called is wrapped with an AnswerDecoration and a
    # Delegate decoration. The latter is used to redirect to the called
    # component. Once the decorations are installed, we end the processing of
    # callbacks prematurely.
    #
    # When at a later point in time the called component invokes #answer, this
    # will raise a AnswerDecoration::Answer exception which is catched by the
    # AnswerDecoration we installed before calling this component, and as such,
    # whose process_callbacks method was called before we gained control.
    #
    # The AnswerDecoration then invokes the <tt>answer_callback</tt> to cleanup
    # the decorations we added during #call and finally passes control to the
    # <tt>return_callback</tt>.
    #
    def call(component, &return_callback)
      delegate = Delegate.new(component)
      answer = AnswerDecoration.new
      answer.answer_callback = UnwindCall.new(self, component, delegate, answer, &return_callback)
      add_decoration(delegate)
      component.add_decoration(answer)
      session.send_response(nil)
    end

    #
    # Reverts the changes made due to Component#call. Is called when
    # Component#call 'answers'.
    #
    class UnwindCall
      def initialize(calling, called, delegate, answer, &return_callback)
        @calling, @called, @delegate, @answer = calling, called, delegate, answer
        @return_callback = return_callback
      end

      def call(answ)
        @calling.remove_decoration(@delegate)
        @called.remove_decoration(@answer)
        @return_callback.call(*answ.args) if @return_callback
      end
    end

    #
    # Similar to method #call, but using continuations.
    #
    def callcc(component)
      delegate = Delegate.new(component)
      answer = AnswerDecoration.new

      add_decoration(delegate)
      component.add_decoration(answer)

      answ = Kernel.callcc {|cc|
        answer.answer_callback = cc
        session.send_response(nil)
      }
      remove_decoration(delegate)
      component.remove_decoration(answer)

      args = answ.args
      case args.size
      when 0
        return
      when 1
        return args.first
      else
        return *args
      end
    end

    #
    # Chooses one of #call or #callcc depending on whether a block is
    # given or not.
    #
    def call!(comp, &block)
      if block
        call comp, &block
      else
        callcc comp
      end
    end

    def call_inline(&render_block)
      callcc BlockComponent.new(&render_block)
    end

    #
    # Return from a called component.
    # 
    # NOTE that #answer never returns.
    #
    # See #call for a detailed description of the call/answer mechanism.
    #
    def answer(*args)
      raise AnswerDecoration::Answer.new(args)
    end

  end # class Component

  class BlockComponent < Component
    def initialize(&block)
      @block = block
    end

    def render(r)
      instance_exec(r, &@block)
    end
  end # class BlockComponent

end # module Wee
