require 'thread'
require 'wee/lru_cache'
require 'wee/id_generator'
require 'wee/renderer'

module Wee

  class Session

    #
    # The default serializer, when no continuation are going to be used.
    # Ensures that only one request of the same session is executed at
    # the same time.
    #
    class MutexSerializer < Mutex
      def call(env)
        synchronize { env['wee.session'].call(env) }
      end
    end

    #
    # This serializer ensures that all requests of a session are
    # executed within the same thread. This is required if continuations 
    # are going to be used.
    #
    # You can run multiple sessions within the same ThreadSerializer, or
    # allocate one ThreadSerializer (and as such one Thread) per session
    # as you want.
    #
    class ThreadSerializer
      def initialize
        @in, @out = Queue.new, Queue.new
        @thread = Thread.new {
          Thread.abort_on_exception = true
          while true 
            env = @in.pop
            @out.push(env['wee.session'].call(env))
          end
        }
      end

      def call(env)
        @in.push(env)
        @out.pop
      end
    end

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
    def initialize(root_component, serializer=nil, page_cache_capacity=20)
      @root_component = root_component
      @page_cache = Wee::LRUCache.new(page_cache_capacity)
      @page_ids = Wee::IdGenerator::Sequential.new
      @current_page = nil

      @running = true

      @expire_after = 30*60
      @max_lifetime = nil
      @max_requests = nil

      @last_access = @creation_time = Time.now 
      @request_count = 0
      
      @serializer = serializer || MutexSerializer.new
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
      if env['wee.session']
        # we are already serialized
        raise if env['wee.session'] != self
        begin
          Thread.current[:wee_session] = self
          @request_count += 1
          @last_access = Time.now
          awake
          response = handle(env)
          sleep
          return response
        ensure
          Thread.current[:wee_session] = nil
        end
      else
        env['wee.session'] = self
        @serializer.call(env)
      end
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
    def handle(env)
      request = Wee::Request.new(env)
      @request = request # CONTINUATIONS!
      page = @page_cache.fetch(request.page_id)

      if page
        if page != @current_page
          @current_page = nil
          page.state.restore
          @current_page = page
        end

        if request.render?
          return render(request, page).finish
        else # request.action?
          return action(request, page).finish
        end
      else
        #
        # either no or invalid page_id specified.  reset to initial state (or
        # create initial state if no such exists yet)
        #
        @initial_state ||= take_snapshot() 
        new_page = Page.new(@page_ids.next, @initial_state, nil) 
        @page_cache[new_page.id] = new_page

        url = request.build_url(:page_id => new_page.id)
        if request.page_id
          return Wee::RefreshResponse.new("Invalid or expired page", url).finish
        else
          return Wee::RedirectResponse.new(url).finish
        end
      end
    ensure
      @request = nil
    end

    def render_ajax_proc(block, component)
      proc {
        r = component.renderer_class.new
        r.session   = self
        r.request   = @request
        r.response  = Wee::Response.new
        r.document  = Wee::HtmlDocument.new
        r.callbacks = @page.callbacks
        r.current_component = component

        begin
          block.call(r)
        ensure
          r.close
        end

        r.response << r.document.to_s
        send_response(r.response)
      }
    end

    public :render_ajax_proc

    def render(request, page)
      r = Wee::Renderer.new
      r.session   = self
      r.request   = request
      r.response  = Wee::GenericResponse.new
      r.document  = Wee::HtmlDocument.new
      r.callbacks = Wee::Callbacks.new

      begin
        @root_component.decoration.render_on(r)
      ensure
        r.close
      end

      r.response << r.document.to_s

      page.callbacks = r.callbacks
      return r.response
    end

    def action(request, page)
      @current_page = nil

      begin
        @page = page # CONTINUATIONS!
        page.callbacks.with_triggered(request.fields) do
          @root_component.decoration.process_callbacks(page.callbacks)
        end
      rescue AbortCallbackProcessing => abort
        page = @page # CONTINUATIONS!
        if abort.response
          #
          # replace the state of the current page
          #
          @current_page = page
          page.state = take_snapshot()
          @page_cache[page.id] = page
          return abort.response
        else
          # pass on - this is a premature response from Component#call
        end
      end
      request = @request # CONTINUATIONS!

      #
      # create new page (state)
      #
      new_page = Page.new(@page_ids.next, take_snapshot(), nil) 
      @page_cache[new_page.id] = new_page
      @current_page = new_page

      url = request.build_url(:page_id => new_page.id)
      return Wee::RedirectResponse.new(url)
    end

    #
    # This method takes a snapshot from the current state of the root component
    # and returns it.
    #
    def take_snapshot
      @root_component.decoration.state(s = Wee::State.new)
      return s.freeze
    end

  end # class Session

end # module Wee
