require 'wee/id_generator'

module Wee

  #
  # A Wee::Application manages all Session's of a single application.  It
  # dispatches the request to the correct handler by examining the request.
  #
  class Application

    #
    # Creates a new application. The block, when called, must
    # return a new Session instance. 
    #
    #   Wee::Application.new { Wee::Session.new(root_component) }
    #
    def initialize(max_sessions=nil, &block)
      @max_sessions = max_sessions
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
    
    def call(env)
      request = Wee::Request.new(env)

      if request.session_id
        session = @mutex.synchronize { @sessions[request.session_id] }
        if session and session.alive?
          session.call(env)
        else
          url = request.build_url(:session_id => nil, :page_id => nil)
          Wee::RefreshResponse.new("Invalid or expired session", url).finish
        end
      else
        session = new_session()
        url = request.build_url(:session_id => session.id, :page_id => nil)
        Wee::RedirectResponse.new(url).finish
      end
    end

    protected

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

    # MUST be called while holding @mutex

    def garbage_collect_handlers
      @sessions.delete_if {|id,rh| rh.dead? }
    end

  end # class Application

end # module Wee
