require 'thread'
require 'wee/lru_cache'

class Wee::Session

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
  attr_accessor :page_store

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
 
  def initialize(root_component, page_store_capacity=20)
    @last_access = @creation_time = Time.now 
    @expire_after = 30*60                  # The default is 30 minutes of inactivity
    @request_count = 0
    @running = true
    
    # to serialize the requests we need a mutex
    @mutex = Mutex.new    

    @root_component = root_component
    @page_store = Wee::LRUCache.new(page_store_capacity)
    @idgen = Wee::SequentialIdGenerator.new
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
    set_response(context, Wee::ErrorResponse.new(exn))
  end

  protected

  def set_response(context, response)
    context.response = response
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

  private

  def current_callbacks
    @page.callbacks
  end

  protected

  # The main routine where the request is processed.

  def process_request
    page_id = @context.request.page_id
    snapshot = nil

    if page_id.nil?

      # No page_id was specified in the URL. This means that we start with a
      # fresh component and a fresh page_id, then redirect to render itself.

      snapshot = initial_page().snapshot

    elsif @page = @page_store.fetch(page_id, false)

      # A valid page_id was specified and the corresponding page exists.

      @page.snapshot.restore if page_id != @snapshot_page_id 

      if @context.request.render?
        # No action/inputs were specified -> render page
        #
        # 1. Reset the action/input fields (as they are regenerated in the
        #    rendering process).
        # 2. Render the page (respond).
        # 3. Store the page back into the store

        # render
        set_response(@context, Wee::GenericResponse.new)
        @context.callbacks = Wee::Callbacks.new
        @context.document = Wee::HtmlWriter.new(@context.response)

        @page.root_component.decoration.render_on(@context)

        @page.callbacks = @context.callbacks
        return
      else
        # Actions/inputs were specified.
        #
        # We process the request and invoke actions/inputs. Then we generate a
        # new page view. 

        begin
          @page.callbacks.with_triggered(@context.request.fields) do
            @page.root_component.decoration.process_callbacks(@page.callbacks)
          end
          snapshot = nil
        rescue Wee::AbortCallbackProcessing => ex 
          if premature_response = ex.response
            # replace existing page with new snapshot
            @page.snapshot = @page.take_snapshot
            @page_store[@context.request.page_id] = @page
            @snapshot_page_id = @context.request.page_id  

            # and send response
            set_response(@context, premature_response) 
            return
          else
            snapshot = nil
          end
        end

      end

    else

      # A page_id was specified in the URL, but there's no page for it in the
      # page store. Either the page has timed out, or an invalid page_id was
      # specified. 

      # TODO:: Display an "invalid page or page timed out" message, which
      # forwards to /app/session-id
      raise "Not yet implemented"

    end

    # handle_new_page_view

    new_page_id = @idgen.next.to_s
    new_page = Wee::Page.new(nil, @root_component, snapshot, Wee::Callbacks.new)
    @page_store[new_page_id] = new_page
    @snapshot_page_id = new_page_id 
    redirect_url = @context.request.build_url(:page_id => new_page_id)
    set_response(@context, Wee::RedirectResponse.new(redirect_url))
  end

  def initial_page
    @initial_page ||= Wee::Page.new(nil, @root_component, nil, nil)
  end

end
