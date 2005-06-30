class Wee::Component

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
  # throwing <i>:wee_abort_callback_processing</i>. This means, that there is
  # only ever one action callback invoked per request.  When at a later point
  # in time the called component invokes #answer, this will throw a
  # <i>:wee_answer</i> exception which is catched in the AnswerDecoration.  The
  # AnswerDecoration then jumps back to the continuation we created at the
  # beginning, and finally method #call returns. 
  #
  # Note that #call returns to an "old" stack-frame from a previous request.
  # That is why we throw <i>:wee_abort_callback_processing</i> after invoking
  # an action callback, and that's why only ever one is invoked. We could
  # remove this limitation without problems, but then there would be a
  # difference between those action callbacks that call other components and
  # those that do not.  

  def call(component, return_callback=:use_continuation, *additional_args)
    add_decoration(delegate = Wee::Delegate.new(component))
    component.add_decoration(answer = Wee::AnswerDecoration.new)

    if return_callback == :use_continuation
      result = callcc {|cc|
        answer.on_answer = cc
        throw :wee_abort_callback_processing, nil
      }
      remove_decoration(delegate)
      component.remove_decoration(answer)
      return result
    else
      answer.on_answer = OnAnswer.new(self, component, delegate, answer,
                                      return_callback, additional_args)
      throw :wee_abort_callback_processing, nil
    end
  end

end
