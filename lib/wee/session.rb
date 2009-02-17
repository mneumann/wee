require 'thread'
require 'wee/lru_cache'

module Wee

  class Session

    class Page < Struct.new(:id, :state, :callbacks); end

    # Points to the Wee::Application object for which this handler is registered. 

    attr_accessor :application

    # Each request handler of an application has a unique id, which should be
    # non-guessable, that means it has to be cryptographically secure.
    #
    # This id is used to uniquely identify a RequestHandler from each other. This
    # is the same id used as a session id in class Wee::Session.

    attr_accessor :id

    # Expire after this number of seconds of inactivity. If this value is +nil+,
    # the RequestHandler will never expire due to inactivity (but may still due
    # to <i>max_lifetime</i>).

    attr_accessor :expire_after

    # The lifetime of this handler is limited to this number of seconds. A value
    # of +nil+ means infinite lifetime.

    attr_accessor :max_lifetime

    # The maximum number of requests this handler should serve. A value of +nil+
    # means infinity.

    attr_accessor :max_requests

    attr_accessor :root_component

    # Terminates the handler. 
    #
    # This will usually not immediatly terminate the handler from running, but
    # further requests will not be answered.

    def teminate
      @running = false
    end

    # Query whether this handler is still alive.

    def alive?
      return false if not @running
      return @running = false if @max_requests and @request_count >= @max_requests

      now = Time.now
      inactivity = now - @last_access 
      lifetime = now - @creation_time

      return @running = false if @expire_after and inactivity > @expire_after 
      return @running = false if @max_lifetime and lifetime > @max_lifetime 
      return true
    end

    def statistics
      now = Time.now
      {
        :last_access => @last_access,        # The time when this handler was last accessed
        :inactivity => now - @last_access,   # The number of seconds of inactivity
        :creation_time => @creation_time,    # The time when this handler was created 
        :lifetime =>  now - @creation_time,  # The uptime or lifetime of this handler in seconds
        :request_count => @request_count     # The number of requests served by this handler
      }
    end
   
    def initialize(root_component, page_cache_capacity=20)
      @last_access = @creation_time = Time.now 
      @expire_after = 30*60                  # The default is 30 minutes of inactivity
      @request_count = 0
      @running = true
      
      # to serialize the requests we need a mutex
      @mutex = Mutex.new    

      @root_component = root_component
      @page_cache = Wee::LRUCache.new(page_cache_capacity)
      @idgen = Wee::IdGenerator::Sequential.new
    end

    def self.current
      Thread.current[:wee_session] || (raise "Not in session")
    end

    # Returns the current context.

    def current_context
      @context
    end

    # Called by Wee::Application to send the session a request.

    def handle_request(context)
      @mutex.synchronize {
        begin
          Thread.current[:wee_session] = self
          @context = context
          @request_count += 1
          @last_access = Time.now
          awake
          process_request
          sleep
        ensure
          @context = nil   # clean up
          Thread.current[:wee_session] = nil
        end
      }
    rescue Exception => exn
      context.response = Wee::ErrorResponse.new(exn)
    end

    protected

    # Is called before process_request is invoked.
    # Can be used to setup e.g. a database connection.
    # 
    # OVERWRITE IT (if you like)!

    def awake
    end

    # Is called after process_request is run.
    # Can be used to release e.g. a database connection.
    # 
    # OVERWRITE IT (if you like)!

    def sleep
    end

    # The main routine where the request is processed.

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
          rescue Wee::AbortCallbackProcessing
          end

          # create new page (state)
          new_page = Page.new(@idgen.next.to_s, take_snapshot(), nil) 
          cache(new_page)
          redirect(new_page)
        end
      else
        # either no or invalid page_id specified.  reset to initial state (or
        # create initial state if no such exists yet)
        
        @initial_state ||= take_snapshot() 
        new_page = Page.new(@idgen.next.to_s, @initial_state, nil) 
        cache(new_page)
        redirect(new_page) # XXX: Show some informative message and wait 5 secs
      end
    end
    
    # This method takes a snapshot from the current state of the root component
    # and returns it.

    def take_snapshot
      @root_component.decoration.backtrack(state = Wee::State.new)
      return state.freeze
    end

    def cache(page)
      @page_cache[page.id] = page
    end

    def redirect(page)
      @context.response = Wee::RedirectResponse.new(
        @context.request.build_url(:page_id => page.id))
    end

    public

    #
    # Send a premature response
    #
    def send_response(response)
      raise Wee::AbortCallbackProcessing.new(response)
    end


  end # class Session

end # module Wee
