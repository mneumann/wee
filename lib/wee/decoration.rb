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
    @owner.process_callbacks(callback_stream)
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
  def initialize(component, delegate)
    super(component)
    @delegate = delegate
  end

  def process_callbacks(callback_stream)
    @delegate.process_callback_chain(callback_stream)
  end

  def render(rendering_context)
    @delegate.render_chain(rendering_context)
  end
end

# A serializable Method class, which stores the literal method name instead of
# an internal tree-node method id.

class LiteralMethod
  def initialize(object, method_name)
    @object, @method_name = object, method_name
  end
  def call(*args)
    @object.send(@method_name, *args)
  end
  alias [] call
end

class Wee::AnswerDecoration < Wee::Decoration

  # When a component answers, <tt>on_answer.call(args)</tt> will be executed
  # (unless nil).

  attr_accessor :on_answer

  def process_callbacks(callback_stream)
    args = catch(:wee_answer) { super; nil }
    unless args.nil?
      # return to the calling component 
      self.remove!
      @on_answer.call(*args) if @on_answer
    end
  end
end
