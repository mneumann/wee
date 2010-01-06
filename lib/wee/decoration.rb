require 'wee/presenter'

module Wee

  #
  # Abstract base class of all decorations. Forwards the methods
  # #process_callbacks, #render! and #state to the next decoration in
  # the chain. Subclasses should provide special behaviour in these methods,
  # otherwise the decoration does not make sense.
  #
  # For example, a HeaderFooterDecoration class could draw a header and footer
  # around the decorations or components below itself:
  #
  #   class HeaderFooterDecoration < Wee::Decoration
  #     alias render! render_presenter!
  #     def render(r)
  #       r.text "header"
  #       r.render_decoration(@next)
  #       r.text "footer"
  #     end
  #   end
  #
  class Decoration < Presenter

    #
    # Points to the next decoration in the chain. A decoration is responsible for
    # all decorations or components "below" it (everything that follows this
    # decoration in the chain). In other words, it's the owner of everything
    # "below" itself.
    #
    attr_accessor :next

    #
    # Is this decoration a global or a local one? By default all decorations are
    # local unless this method is overwritten.
    #
    # A global decoration is added in front of the decoration chain, a local
    # decoration is added in front of all other local decorations but after all
    # global decorations.
    #
    def global?() false end

    #
    # Forwards method call to the next decoration in the chain.
    #
    def process_callbacks(callbacks)
      @next.process_callbacks(callbacks)
    end

    alias render_presenter! render!
    #
    # Forwards method call to the next decoration in the chain.
    #
    def render!(r)
      @next.render!(r)
    end

    #
    # We have to save the @next attribute to be able to correctly backtrack
    # calls, as method Wee::Component#call modifies it in the call to
    # <tt>component.remove_decoration(answer)</tt>. Removing the
    # answer-decoration has the advantage to be able to call a component more
    # than once!
    #
    def state(s)
      @next.state(s)
      s.add_ivar(self, :@next, @next)
    end

  end # class Decoration

  #
  # A Wee::Delegate breaks the decoration chain and forwards the methods
  # #process_callbacks, #render! and #state to the corresponding *chain*
  # method of it's _delegate_ component (a Wee::Component).
  #
  class Delegate < Decoration

    def initialize(delegate)
      @delegate = delegate
    end

    #
    # Forwards method to the corresponding top-level *chain* method of the
    # _delegate_ component.
    #
    def process_callbacks(callbacks)
      @delegate.decoration.process_callbacks(callbacks)
    end

    #
    # Forwards method to the corresponding top-level *chain* method of the
    # _delegate_ component.
    #
    def render!(r)
      @delegate.decoration.render!(r)
    end

    #
    # Forwards method to the corresponding top-level *chain* method of the
    # _delegate_ component. We also take snapshots of all non-visible
    # components, thus we follow the @next decoration (via super).
    #
    def state(s)
      super
      @delegate.decoration.state(s)
    end

  end # class Delegate

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


  class WrapperDecoration < Decoration

    alias render! render_presenter!

    #
    # Overwrite this method, and call render_inner(r) 
    # where you want the inner content to be drawn.
    #
    def render(r)
      render_inner(r)
    end

    def render_inner(r)
      r.render_decoration(@next)
    end

  end # class WrapperDecoration


  #
  # Renders a <div> tag with a unique "id" around the wrapped component. 
  # Useful for components that want to update their content in-place using
  # AJAX. 
  #  
  class OidDecoration < WrapperDecoration
    def render(r)
      r.div.oid.with { render_inner(r) }
    end
  end # class OidDecoration

  #
  # Renders a CSS style for a component class.
  #
  # Only works when used together with a PageDecoration,
  # or an existing :styles divert location.
  #
  # The style is not rendered when in an AJAX request.
  # This is the desired behaviour as it is assumed that
  # a component is first rendered via a regular request
  # and then updated via AJAX requests.
  #
  # It is only rendered once for all instances of a given
  # component.
  #
  # A method #style must exist returning the CSS style.
  #
  class StyleDecoration < WrapperDecoration
    def initialize(component)
      @component = component
    end

    def render(r)
      r.render_style(@component)
      render_inner(r)
    end
  end # class StyleDecoration

  class FormDecoration < WrapperDecoration

    def global?() true end

    def render(r)
      r.form { render_inner(r) }
    end

  end # class FormDecoration

  class PageDecoration < WrapperDecoration

    def initialize(title='', stylesheets=[], javascripts=[])
      @title = title
      @stylesheets = stylesheets
      @javascripts = javascripts
      super()
    end

    def global?() true end

    def render(r)
      r.page.title(@title).head {
        @stylesheets.each {|s| r.link_css(s) }
        @javascripts.each {|j| r.javascript.src(j) }
        r.style.type('text/css').with { r.define_divert(:styles) }
        r.javascript.with { r.define_divert(:javascripts) }
      }.with {
        render_inner(r)
      }
    end

  end # class PageDecoration

end # module Wee
