class Wee::Context
  attr_accessor :request, :response, :session

  def initialize(request=nil, response=nil, session=nil)
    @request, @response, @session = request, response, session
  end
end

class Wee::RenderingContext < Wee::Context
  attr_accessor :callbacks, :document

  def initialize(request=nil, response=nil, session=nil, callbacks=nil, document=nil)
    super(request, response, session)
    @callbacks, @document = callbacks, document 
  end
end
