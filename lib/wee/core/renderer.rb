# Base class of all Renderer classes.

class Wee::Renderer
  attr_reader   :rendering_context   # holds the current Wee::RenderingContext
  attr_accessor :current_component

  def initialize(rendering_context, current_component=nil, &block)
    @rendering_context = rendering_context
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
