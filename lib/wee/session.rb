require 'wee/page'
require 'thread'

class Wee::Session < Wee::RequestHandler
  attr_accessor :root_component, :page_store

  def self.current
    sess = Thread.current[:wee_session]
    raise "not in session" if sess.nil?
    return sess
  end

  def initialize(&block)
    Thread.current[:wee_session] = self

    @idgen = Wee::SimpleIdGenerator.new

    # to serialize the requests we need a mutex
    @mutex = Mutex.new    

    block.call(self)

    raise ArgumentError, "No root component specified" if @root_component.nil?
    raise ArgumentError, "No page_store specified" if @page_store.nil?
    
    @initial_snapshot = snapshot()

    super()
  ensure
    Thread.current[:wee_session] = nil
  end

  def snapshot
    @root_component.backtrack_state_chain(snap = Wee::Snapshot.new)
    return snap.freeze
  end

  # called by application to send the session a request

  def handle_request(context)
    @mutex.synchronize do
      begin
        Thread.current[:wee_session] = self
        @context = context
        super
        awake
        process_request
        sleep
      rescue Exception => exn
        set_response(context, Wee::ErrorResponse.new(exn))
      ensure
        Thread.current[:wee_session] = nil
        @context = nil
        @page = nil
      end
    end
  end

  def create_page(snapshot)
    idgen = Wee::SimpleIdGenerator.new
    page = Wee::Page.new(snapshot, Wee::CallbackRegistry.new(idgen))
  end

  # Is called before process_request is invoked
  # Can be used to setup e.g. a database connection.
  def awake
  end

  # Is called after process_request is run
  # Can be used to release e.g. a database connection.
  def sleep
  end

  def process_request
    if @context.request.page_id.nil?

      # No page_id was specified in the URL. This means that we start with a
      # fresh component and a fresh page_id, then redirect to render itself.

      handle_new_page_view(@context, @initial_snapshot)

    elsif @page = @page_store.fetch(@context.request.page_id, false)

      # A valid page_id was specified and the corresponding page exists.

      @page.snapshot.restore if @context.request.page_id != @snapshot_page_id 

      p @context.request.fields if $DEBUG

      if @context.request.fields.empty?

        # No action/inputs were specified -> render page
        #
        # 1. Reset the action/input fields (as they are regenerated in the
        #    rendering process).
        # 2. Render the page (respond).
        # 3. Store the page back into the store

        @page = create_page(@page.snapshot)  # remove all action/input handlers
        respond(@context, @page.callbacks)                    # render
        @page_store[@context.request.page_id] = @page         # store

      else

        # Actions/inputs were specified.
        #
        # We process the request and invoke actions/inputs. Then we generate a
        # new page view. 

        callback_stream = Wee::CallbackStream.new(@page.callbacks, @context.request.fields) 

        if callback_stream.all_of_type(:action).size > 1 
          raise "Not allowed to specify more than one action callback"
        end

        live_update_response = catch(:wee_live_update) {
          catch(:wee_back_to_session) {
            @root_component.process_callbacks_chain(callback_stream)
          }
          nil
        }

        if live_update_response
          # replace existing page with new snapshot
          @page.snapshot = self.snapshot
          @page_store[@context.request.page_id] = @page
          @snapshot_page_id = @context.request.page_id  
          set_response(@context, live_update_response) 
        else
          handle_new_page_view(@context)
        end

      end

    else

      # A page_id was specified in the URL, but there's no page for it in the
      # page store.  Either the page has timed out, or an invalid page_id was
      # specified. 
      #
      # TODO:: Display an "invalid page or page timed out" message, which
      # forwards to /app/session-id

      raise "Not yet implemented"

    end
  end

  def current_context
    @context
  end

  def current_callbacks
    @page.callbacks
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  # :section: Properties
  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  attr_accessor :properties

  # Returns an "owned" property for the given +klass+.

  def get_property(prop, klass)
    if @properties
      @properties.fetch(klass, {})[prop]
    else
      nil
    end
  end

  private

  def handle_new_page_view(context, snapshot=nil)
    new_page_id = @idgen.next.to_s
    new_page = create_page(snapshot || self.snapshot())
    @page_store[new_page_id] = new_page
    @snapshot_page_id = new_page_id 
    redirect_url = context.request.build_url(context.request.request_handler_id, new_page_id)
    set_response(context, Wee::RedirectResponse.new(redirect_url))
  end

  def set_response(context, response)
    context.response = response
  end

  def respond(context, callbacks)
    set_response(context, Wee::GenericResponse.new('text/html', ''))

    rctx = Wee::RenderingContext.new(context.request, context.response, callbacks, Wee::HtmlWriter.new(context.response.content))
    @root_component.do_render_chain(rctx)
  end

end
