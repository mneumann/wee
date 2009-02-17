module Wee

  #
  # A Wee::AnswerDecoration is wrapped around a component that will call
  # Component#answer. This makes it possible to use such components without the
  # need to call them (Component#call), e.g. as child components of other
  # components.
  #
  class AnswerDecoration < Decoration

    #
    # When a component answers, <tt>on_answer.call(args)</tt> will be executed
    # (unless nil), where +args+ are the arguments passed to Component#answer.
    # Note that no snapshot of on_answer is taken, so you should avoid
    # modifying it!
    #
    attr_accessor :on_answer

    def process_callbacks(callbacks)
      args = catch(:wee_answer) { super; nil }
      if args != nil
        # return to the calling component 
        @on_answer.call(*args) if @on_answer
      end
    end

  end # class AnswerDecoration

  module CallAnswerMixin

    protected

    #
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
    def call(component, &return_callback)
      delegate = Wee::Delegate.new(component)
      answer = Wee::AnswerDecoration.new
      answer.on_answer = OnAnswer.new(self, component, delegate, answer, return_callback)

      add_decoration(delegate)
      component.add_decoration(answer)
      session.send_response(nil)
    end

    class OnAnswer < Struct.new(:calling_component, :called_component, 
                                :delegate, :answer, :return_callback)

      def call(*answer_args)
        calling_component.remove_decoration(delegate)
        called_component.remove_decoration(answer)
        return_callback.call(*answer_args) if return_callback
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

  end # module CallAnswerMixin

end # module Wee
