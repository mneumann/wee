require 'wee/page'
require 'wee/state_registry'
require 'wee/callback'
require 'thread'

class Wee::Session
  attr_accessor :root_component, :page_store
  attr_reader :state_registry

  def self.current
    sess = Thread.current['Wee::Session']
    raise "not in session" if sess.nil?
    return sess
  end

  def register_object_for_backtracking(obj)
    @state_registry << obj
  end

  def initialize(&block)
    Thread.current['Wee::Session'] = self

    @next_page_id = 0
    @state_registry = Wee::StateRegistry.new
    @in_queue, @out_queue = SizedQueue.new(1), SizedQueue.new(1)

    @continuation_stack = []
    register_object_for_backtracking(@continuation_stack)

    block.call(self)

    raise ArgumentError, "No root component specified" if @root_component.nil?
    raise ArgumentError, "No page_store specified" if @page_store.nil?
    
    @initial_snapshot = @state_registry.snapshot 
    start_request_response_loop
  ensure
    Thread.current['Wee::Session'] = nil
  end

  # called by application to send the session a request
  def handle_request(context)

    # Send a request to the session. If the session is currently busy
    # processing another request, this will block. 
    @in_queue.push(context)

    # Wait for the response.
    context = @out_queue.pop

    # TODO: can't move into session?
    if context.redirect
      context.response.set_redirect(WEBrick::HTTPStatus::MovedPermanently, context.redirect)
    end
  end

  def start_request_response_loop
    Thread.abort_on_exception = true
    Thread.new {
      Thread.current['Wee::Session'] = self

      loop {
        @context = @in_queue.pop
        process_request
        @out_queue.push(@context)
      }
    }
  end

  attr_reader :continuation_stack

  def process_request
    if @context.page_id.nil?

      # No page_id was specified in the URL. This means that we start with a
      # fresh component and a fresh page_id, then redirect to render itself.

      handle_new_page_view(@context, @initial_snapshot)

    elsif page = @page_store.fetch(@context.page_id, false)

      # A valid page_id was specified and the corresponding page exists.

      page.snapshot.apply

      if @context.handler_id.nil?

        # No action/inputs were specified -> render page
        #
        # 1. Reset the action/input fields (as they are regenerated in the
        #    rendering process).
        # 2. Render the page (respond).
        # 3. Store the page back into the store

        page = Wee::Page.new(page.snapshot, Wee::CallbackRegistry.new)  # remove all action/input handlers
        @context.callback_registry = page.callback_registry
        respond(@context)                            # render
        @page_store[@context.page_id] = page         # store

      else

        # Actions/inputs were specified.
        #
        # We process the request and invoke actions/inputs. Then we generate a
        # new page view. 

        s = {@context.handler_id => nil}.update(@context.request.query)
        callback_stream = page.callback_registry.create_callback_stream(s)

        @root_component.process_callback_chain(callback_stream)
        handle_new_page_view(@context)

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

  private

  def handle_new_page_view(context, snapshot=nil)
    new_page_id = create_new_page_id() 
    new_page = Wee::Page.new(snapshot || @state_registry.snapshot, Wee::CallbackRegistry.new)
    @page_store[new_page_id] = new_page

    redirect_url = "#{ context.application.path }/s:#{ context.session_id }/p:#{ new_page_id }"
    context.redirect = redirect_url
  end

  def respond(context)
    context.response.status = 200
    context.response['Content-Type'] = 'text/html'

    rctx = Wee::RenderingContext.new(context, Wee::HtmlWriter.new(context.response.body))
    @root_component.render_chain(rctx)
  end

  def create_new_page_id
    @next_page_id.to_s
  ensure
    @next_page_id += 1
  end

end
