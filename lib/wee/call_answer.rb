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

end # module Wee
