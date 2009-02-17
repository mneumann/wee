require 'wee/id_generator'

module Wee

  # A Wee::Application manages all Wee::RequestHandler's of a single application,
  # where most of the time the request handlers are Wee::Session objects. It
  # dispatches the request to the correct handler by examining the request.

  class Application

    #
    # The maximum number of sessions
    #
    attr_accessor :max_sessions

    #
    # Creates a new application. The block, when called, must
    # return a new Session instance. 
    #
    #   Wee::Application.new { Wee::Session.new(rootcomponent) }
    #
    def initialize(&block)
      @session_factory = block || raise(ArgumentError)
      @session_ids ||= Wee::IdGenerator::Secure.new

      @sessions = Hash.new
      @mutex = Mutex.new

      # start request-handler collecting thread
      # run once every minute
      @gc_thread = Thread.new {
        sleep 60
        @mutex.synchronize { garbage_collect_handlers }
      }
    end

    def new_session
      session = @session_factory.call
      session.id = unique_session_id()
      @sessions[session.id] = session
      session.application = self
      return session
    end

    def unique_session_id
      3.times do
        id = @session_ids.next
        return id if @sessions[id].nil?
      end
      raise
    end
    
    def handle_request(context)
      session_id = context.request.session_id
      session = @mutex.synchronize { @sessions[session_id] }

      if session_id.nil?
        # No id was given -> check whether the maximum number of sessions
        # is reached. if not, create new id and handler
        session = new_session()
        context.request.session_id = session.id 
        session.handle_request(context)
      elsif session.nil? or session.dead?
        session_expired(context)
      else
        session.handle_request(context)
      end

    rescue => exn
      context.response = Wee::ErrorResponse.new(exn) 
    end

=begin
    def insert_new_request_handler(request_handler)
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

        request_handler.id = unique_request_handler_id()
        request_handler.application = self
        @request_handlers[request_handler.id] = request_handler
      }
    end
=end

    private

    # MUST be called while holding @mutex

    def garbage_collect_handlers
      @sessions.delete_if {|id,rh| rh.dead? }
    end

    def session_expired(context)
      context.response = Wee::RefreshResponse.new("Invalid or expired session!",
                         context.request.build_url(:session_id => nil,
                                                   :page_id => nil))
    end

  end # class Application

end # module Wee
