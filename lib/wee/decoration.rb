class Wee::Decoration < Wee::Presenter

  # A pointer back to the component for which the decoration was specified.

  attr_accessor :component

  # Points to the next decoration in the chain. A decoration is responsible for
  # all decorations or components "below" it (everything that follows this
  # decoration in the chain). In other words, it's the owner of everything
  # "below" itself.

  attr_accessor :owner   

  # Go on with the next decoration in the chain.

  def process_callbacks(callback_stream)
    @owner.process_callback_chain(callback_stream)
  end

  # Go on with the next decoration in the chain.

  def render(rendering_context)
    @owner.render(rendering_context)
  end

  # Remove this decoration from the decoration chain.

  def remove!
    raise if @component.remove_decoration(self) != self
  end

  protected

  def initialize(component)
    @component = component
    @owner = nil
  end

end

class Wee::Delegate < Wee::Decoration
  def initialize(component, delegatee)
    super(component)
    @delegatee = delegatee
  end

  def process_callbacks(callback_stream)
    @delegatee.process_callback_chain(callback_stream)
  end

  def render(rendering_context)
    @delegatee.render_chain(rendering_context)
  end
end

class Wee::AnswerDecoration < Wee::Delegate
  attr_accessor :return_method

  def process_callbacks(callback_stream)
    args = catch(:wee_answer_call) { super; nil }
    unless args.nil?
      # return to the calling component 
      self.remove!
      @component.send(@return_method, *args) if @return_method 
    end
  end
end
