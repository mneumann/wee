class Wee::Application
  attr_accessor :name, :path
  attr_accessor :session_store, :session_class

  def initialize(&block)
    setup_session_id_generator

    block.call(self)

    if [@name, @path, @session_class, @session_store].any? {|i| i.nil?}
      raise ArgumentError, "missing name, path, session_class or session_store" 
    end
  end

  def setup_session_id_generator
    @session_cnt = rand(1000_000)
  end

  def handle_request(req, res)
    hash = parse_url(req)

    session_id = hash['s']
    if session_id.nil? 
      # TODO:
      # gen session, or assign default session (by default, do not show).
      # but for a default session, we have to have thread-safe components (without @context=... hack)

      session = @session_class.new
      session_id = gen_unique_session_id
      session.id = session_id
      session.application = self
      @session_store[session_id] = session
    end

    session = @session_store[session_id]
    if session.nil?
      # TODO: redirect to session-less page, or do whatever
      error_invalid_session(req, res); return
    end

    context = Wee::Context.new(req, res, session, session_id)
    context.application = self
    context.session = session
    context.page_id = hash['p']
    context.handler_id = hash['h']
    session.handle_request(context)

    # TODO: move into RequestHandler (Session)
    res.status = context.response.status
    res.body = context.response.content
    context.response.header.each { |k,v| res.header[k] = v }
  end

  # TODO: UrlModel, which knows how to create and parse URLs
  def gen_handler_url(session_id, page_id, handler_id)
    [
      self.path, 
      ['s', session_id].join(':'), 
      ['p', page_id].join(':'),
      ['h', handler_id].join(':')
    ].join('/')
  end

  def error_invalid_session(req, res)
    Wee::ErrorPage.new('Invalid Session').respond(Wee::Context.new(req,res,nil,nil))
  end

  private

  # TODO: that's insecure. it's just for development!
  def gen_unique_session_id
    (@session_cnt += 1).to_s
  end

end
