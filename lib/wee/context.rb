class Wee::Context
  attr_accessor :application
  attr_accessor :request, :response, :session, :session_id
  attr_accessor :page_id, :handler_id, :resource_id
  attr_accessor :handler_registry

  def initialize(request, response, session, session_id)
    @request, @response, @session, @session_id, @root = request, response, session, session_id
  end

  def input_ids
    request.query
  end

  def action_ids
    a = request.query.to_a
    a.unshift [handler_id, nil]
    a
  end
end

class Wee::RenderingContext < Struct.new(:context, :document); end
