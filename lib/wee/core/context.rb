class Wee::Context
  attr_accessor :request, :response, :session

  def initialize(request=nil, response=nil, session=nil)
    @request, @response, @session = request, response, session
  end
end

class Wee::RenderingContext
  attr_accessor :context, :callbacks, :document

  def initialize(context=nil, callbacks=nil, document=nil)
    @context, @callbacks, @document = context, callbacks, document 
  end

  def request
    @context.request
  end

  def response
    @context.response
  end

  def session
    @context.session
  end
end
