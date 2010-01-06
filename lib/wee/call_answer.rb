module Wee

  #
  # A Wee::AnswerDecoration is wrapped around a component that will call
  # Component#answer. This makes it possible to use such components without the
  # need to call them (Component#call), e.g. as child components of other
  # components.
  #
  class AnswerDecoration < Decoration

    #
    # Used to unwind the component call chain in Component#answer.
    #
    class Answer < Exception
      attr_reader :args
      def initialize(args) @args = args end
    end

    attr_accessor :answer_callback

    class Interceptor
      attr_accessor :action_callback, :answer_callback

      def initialize(action_callback, answer_callback)
        @action_callback, @answer_callback = action_callback, answer_callback
      end

      def call
        @action_callback.call
      rescue Answer => answer
        # return to the calling component 
        @answer_callback.call(answer)
      end
    end

    #
    # When a component answers, <tt>@answer_callback.call(answer)</tt>
    # will be executed, where +answer+ is of class Answer which includes the
    # arguments passed to Component#answer.
    #
    def process_callbacks(callbacks)
      if action_callback = super
        Interceptor.new(action_callback, @answer_callback)
      else
        nil
      end
    end

  end # class AnswerDecoration

  module CallAnswerMixin

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

  end # module CallAnswerMixin

end # module Wee
