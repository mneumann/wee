require 'wee/page'
require 'wee/state_registry'
require 'wee/handler_registry'
require 'thread'

class Wee::Session
  attr_accessor :page_store
  attr_reader :state_registry
  attr_reader :root_component

  def initialize(&block)
    @next_page_id = 0
    @state_registry = Wee::StateRegistry.new
    @in_queue, @out_queue = SizedQueue.new(1), SizedQueue.new(1)

    @initial_snapshot = @state_registry.snapshot 
    start_request_response_loop
  end

  def self.current
    sess = Thread.current['Wee::Session']
    raise "not in session" if sess.nil?
    return sess
  end

  def register_object_for_backtracking(obj)
    @state_registry << obj
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
      @root_component = root_component()

      loop {
        @context = @in_queue.pop
        process_request
        @out_queue.push(@context)
      }
    }
  end

  def process_request
    if @context.page_id.nil?

      # No page_id was specified in the URL. This means that we start with a
      # fresh component and a fresh page_id, then redirect to render itself.

      handle_new_page_view(@context, @initial_snapshot)

    elsif page = @page_store.fetch(@context.page_id, false)

      # A valid page_id was specified and the corresponding page exists.

      page.snapshot.apply unless @context.resource_id

      raise "invalid request URL! both request_id and handler_id given!" if @context.resource_id and @context.handler_id

      if @context.resource_id
        # This is a resource request
        res = page.handler_registry.get_resource(@context.resource_id)

        @context.response.status = 200
        @context.response['Content-Type'] = res.content_type
        @context.response.body = res.content

      elsif @context.handler_id.nil?

        # No action/inputs were specified -> render page
        #
        # 1. Reset the action/input fields (as they are regenerated in the
        #    rendering process).
        # 2. Render the page (respond).
        # 3. Store the page back into the store (only neccessary if page is not
        #    stored in memory).

        page = Wee::Page.new(page.snapshot, Wee::HandlerRegistry.new)  # remove all action/input handlers
        @context.handler_registry = page.handler_registry
        respond(@context)                     # render
        @page_store[@context.page_id] = page         # store

      else

        # Actions/inputs were specified.
        #
        # We process the request and invoke actions/inputs. Then we generate a
        # new page view. 

        @context.handler_registry = page.handler_registry
        catch(:back_to_request_response_loop) {
          @root_component.decoration.process_request(@context)
        }
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
    new_page = Wee::Page.new(snapshot || @state_registry.snapshot, Wee::HandlerRegistry.new)
    @page_store[new_page_id] = new_page

    redirect_url = "#{ context.application.path }/s:#{ context.session_id }/p:#{ new_page_id }"
    context.redirect = redirect_url
  end

  def respond(context)
    context.response.status = 200
    context.response['Content-Type'] = 'text/html'

    rctx = Wee::RenderingContext.new(context, Wee::HtmlWriter.new(context.response.body))
    renderer = Wee::HtmlCanvas.new(rctx)
    @root_component.render_on(renderer)
  end

  def create_new_page_id
    @next_page_id.to_s
  ensure
    @next_page_id += 1
  end

end
