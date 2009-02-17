require 'thread'
require 'wee/lru_cache'
require 'wee/id_generator'

module Wee

  class Session

    class Page < Struct.new(:id, :state, :callbacks); end

    class AbortCallbackProcessing < Exception
      attr_reader :response
      def initialize(response)
        @response = response
      end
    end

    #
    # The (application-wide) unique id of this session.
    #
    attr_accessor :id

    #
    # Points to the Wee::Application object this session belongs to.
    #
    attr_accessor :application

    #
    # Expire the session after this number of seconds of inactivity. If this
    # value is +nil+, the Session will never expire due to inactivity.
    # (but still may expire for example due to <i>max_lifetime</i>).
    #
    # Default: <tt>1800</tt> seconds (30 minutes)
    #
    attr_accessor :expire_after

    #
    # The maximum lifetime of this session in seconds. A value of +nil+ means
    # infinite lifetime.
    #
    # Default: <tt>nil</tt> (infinite lifetime)
    #
    attr_accessor :max_lifetime

    #
    # The maximum number of requests this session is allowed to serve.
    # A value of +nil+ means no limitation.
    #
    # Default: <tt>nil</tt> (infinite number of requests)
    #
    attr_accessor :max_requests

    #
    # Creates a new session.
    #
    def initialize(root_component, page_cache_capacity=20)
      @root_component = root_component
      @page_cache = Wee::LRUCache.new(page_cache_capacity)
      @page_ids = Wee::IdGenerator::Sequential.new

      @running = true

      @expire_after = 30*60
      @max_lifetime = nil
      @max_requests = nil

      @last_access = @creation_time = Time.now 
      @request_count = 0
      
      # to serialize the requests we need a mutex
      @mutex = Mutex.new    
    end

    #
    # Terminates the session. 
    #
    # This will usually not immediatly terminate the session from running, but
    # further requests will not be answered.
    #
    def terminate
      @running = false
    end

    #
    # Queries whether the session is still alive.
    #
    def alive?
      now = Time.now
      return false if not @running
      return false if @expire_after and now - @last_access > @expire_after 
      return false if @max_lifetime and now - @creation_time > @max_lifetime 
      return false if @max_requests and @request_count >= @max_requests
      return true
    end

    #
    # Queries whether the session is dead.
    #
    def dead?
      not alive?
    end

    #
    # Returns some statistics
    #
    def statistics
      now = Time.now
      {
        :last_access => @last_access,        # The time when this session was last accessed
        :inactivity => now - @last_access,   # The number of seconds of inactivity
        :creation_time => @creation_time,    # The time at which this session was created 
        :lifetime =>  now - @creation_time,  # The lifetime of this session in seconds
        :request_count => @request_count     # The number of requests served by this session
      }
    end
   
    #
    # Returns the current session (thread-local).
    #
    def self.current
      Thread.current[:wee_session] || (raise "Not in session")
    end

    #
    # Handles a web request.
    #
    def call(env)
      @mutex.synchronize {
        begin
          Thread.current[:wee_session] = self
          @request_count += 1
          @last_access = Time.now
          @context = Wee::Context.new(Wee::Request.new(env))
          awake
          process_request
          sleep
          return @context.response.finish
        ensure
          @context = nil   # clean up
          Thread.current[:wee_session] = nil
        end
      }
    end

    #
    # Send a premature response
    #
    def send_response(response)
      raise AbortCallbackProcessing.new(response)
    end

    protected

    #
    # Is called before <i>process_request</i> is invoked.
    #
    # Can be used e.g. to setup a database connection.
    #
    def awake
    end

    #
    # Is called after <i>process_request</i> is run.
    #
    # Can be used e.g. to release a database connection.
    #
    def sleep
    end

    #
    # The main routine where the request is processed.
    #
    def process_request
      page = @page_cache.fetch(@context.request.page_id)

      if page
        # sestore state
        page.state.restore # XXX

        if @context.request.render?
          @context.response = Wee::GenericResponse.new
          @context.callbacks = Wee::Callbacks.new
          @context.document = Wee::HtmlWriter.new(@context.response)

          @root_component.decoration.render_on(@context)

          page.callbacks = @context.callbacks
        else
          begin
            page.callbacks.with_triggered(@context.request.fields) do
              @root_component.decoration.process_callbacks(page.callbacks)
            end
          rescue AbortCallbackProcessing
          end

          # create new page (state)
          new_page = Page.new(@page_ids.next, take_snapshot(), nil) 
          cache(new_page)
          redirect(new_page)
        end
      else
        # either no or invalid page_id specified.  reset to initial state (or
        # create initial state if no such exists yet)
        
        @initial_state ||= take_snapshot() 
        new_page = Page.new(@page_ids.next, @initial_state, nil) 
        cache(new_page)
        redirect(new_page) # XXX: Show some informative message and wait 5 secs
      end
    end
    
    #
    # This method takes a snapshot from the current state of the root component
    # and returns it.
    #
    def take_snapshot
      @root_component.decoration.backtrack(state = Wee::State.new)
      return state.freeze
    end

    def cache(page)
      @page_cache[page.id] = page
    end

    def redirect(page)
      url = @context.request.build_url(:page_id => page.id)
      @context.response = Wee::RedirectResponse.new(url)
    end

  end # class Session

end # module Wee
