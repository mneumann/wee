# A Wee::Application manages all Wee::RequestHandler's of a single application,
# where most of the time the request handlers are Wee::Session objects. It
# dispatches the request to the correct handler by examining the request.

class Wee::Application

  # The generator used for creating unique request handler id's.

  attr_accessor :id_generator

  # The maximum number of request handlers

  attr_accessor :max_request_handlers

  # Get or set the default request handler. The default request handler is used
  # if no request handler id is given in a request. 

  def default_request_handler(&block)
    if block.nil?
      @default_request_handler
    else
      @default_request_handler = block
    end
  end

  # Creates a new application. The block is used to initialize the attributes:
  #
  #   Wee::Application.new {|app|
  #     app.default_request_handler { MySession.new } 
  #     app.id_generator = Wee::SimpleIdGenerator.new
  #     app.max_request_handlers = 1000 
  #   }

  def initialize(&block)
    @request_handlers = Hash.new
    block.call(self)
    @id_generator ||= Wee::SimpleIdGenerator.new(rand(1_000_000))
    if @default_request_handler.nil?
      raise ArgumentError, "No default request handler specified"
    end
    @mutex = Mutex.new

    # start request-handler collecting thread
    # run once every minute
    @gc_thread = Thread.new {
      sleep 60
      @mutex.synchronize { garbage_collect_handlers }
    }
  end
  
  def handle_request(context)
    request_handler_id = context.request.request_handler_id
    request_handler = @mutex.synchronize { @request_handlers[request_handler_id] }

    if request_handler_id.nil?

      # No id was given -> check whether the maximum number of request-handlers
      # limit is reached. if not, create new id and handler

      @mutex.synchronize {
        if @max_request_handlers != nil and @request_handlers.size >= @max_request_handlers
          # limit reached -> remove non-alive handlers...
          garbage_collect_handlers()

          # ...and test again
          if @request_handlers.size >= @max_request_handlers
            # TODO: show a custom error message
            raise "maximum number of request-handlers reached" 
          end
        end

        request_handler_id =  unique_request_handler_id()
        request_handler = @default_request_handler.call  
        request_handler.id = request_handler_id
        request_handler.application = self
        @request_handlers[request_handler_id] = request_handler
      }

      context.response = Wee::RedirectResponse.new(context.request.build_url(request_handler_id))
      return

    elsif request_handler.nil?

      # A false request handler id was given. This might indicate that a
      # request handler has expired. 

      request_handler_expired(context)
      return

    elsif !request_handler.alive?

      # The request_handler is not alive anymore.

      request_handler_expired(context)
      return

    end

    request_handler.handle_request(context)

  rescue => exn
    context.response = Wee::ErrorResponse.new(exn) 
  end

  private

  # MUST be called while holding @mutex

  def unique_request_handler_id
    id = @id_generator.next.to_s
    raise "failed to create unique request handler id" if @request_handlers.include?(id)
    return id
  end

  # MUST be called while holding @mutex

  def garbage_collect_handlers
    @request_handlers.delete_if {|id,rh| !rh.alive? }
  end

  def request_handler_expired(context)
    context.response = Wee::RefreshResponse.new("Invalid or expired request handler!", context.request.application_path)
  end

end
