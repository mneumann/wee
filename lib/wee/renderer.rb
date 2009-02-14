# Base class of all Renderer classes.

class Wee::Renderer
  attr_reader   :context   # holds the current Wee::Context
  attr_accessor :current_component

  def initialize(context, current_component=nil, &block)
    @context = context
    @current_component = current_component
    if block
      begin
        block.call(self)
      ensure
        close
      end
    end
  end

  # Subclass responsibility.

  def close
  end
end
