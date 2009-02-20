require 'wee/presenter'

module Wee

  #
  # Abstract base class of all decorations. Forwards the methods
  # #process_callbacks, #render_on and #backtrack to the next decoration in
  # the chain. Subclasses should provide special behaviour in these methods,
  # otherwise the decoration does not make sense.
  #
  # For example, a HeaderFooterDecoration class could draw a header and footer
  # around the decorations or components below itself:
  #
  #   class HeaderFooterDecoration < Wee::Decoration
  #     alias render_on render_presenter_on
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

    alias render_presenter_on render_on
    #
    # Forwards method call to the next decoration in the chain.
    #
    def render_on(r)
      @next.render_on(r)
    end

    #
    # We have to save the @next attribute to be able to correctly backtrack
    # calls, as method Wee::Component#call modifies it in the call to
    # <tt>component.remove_decoration(answer)</tt>. Removing the
    # answer-decoration has the advantage to be able to call a component more
    # than once!
    #
    def backtrack(state)
      @next.backtrack(state)
      state.add_ivar(self, :@next, @next)
    end

  end # class Decoration

  module DecorationMixin

    attr_accessor :decoration

    #
    # Iterates over all decorations (note that the component itself is excluded). 
    #
    def each_decoration # :yields: decoration
      d = @decoration
      while d and d != self
        yield d
        d = d.next
      end
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
        d.next = @decoration
        @decoration = d
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
          d.next = @decoration
          @decoration = d
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
      if d == @decoration  # 'd' is in front
        @decoration = d.next
      else
        last_decoration = @decoration
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

  end # module DecorationMixin

  #
  # A Wee::Delegate breaks the decoration chain and forwards the methods
  # #process_callbacks, #render_on and #backtrack to the corresponding *chain*
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
    def render_on(r)
      @delegate.decoration.render_on(r)
    end

    #
    # Forwards method to the corresponding top-level *chain* method of the
    # _delegate_ component. We also take snapshots of all non-visible
    # components, thus we follow the @next decoration (via super).
    #
    def backtrack(state)
      super
      @delegate.decoration.backtrack(state)
    end

  end # class Delegate

  class WrapperDecoration < Decoration

    alias render_on render_presenter_on

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

  class FormDecoration < WrapperDecoration

    def render(r)
      r.form { render_inner(r) }
    end

  end # class FormDecoration

  class PageDecoration < WrapperDecoration

    def initialize(title='')
      @title = title
      super()
    end

    def global?() true end

    def render(r)
      r.page.title(@title).with { render_inner(r) }
    end

  end # class PageDecoration

end # module Wee
