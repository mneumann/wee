require 'wee/abstractsession'

class Wee::Session < Wee::AbstractSession

  attr_accessor :root_component
  attr_accessor :page_store

  def initialize(&block)
    super()
    setup(&block)
  end

  def current_callbacks
    @page.callbacks
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  # :section: Request processing/handling
  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  protected

  def setup(&block)
    @idgen = Wee::SequentialIdGenerator.new

    with_session do
      block.call(self) if block
      raise ArgumentError, "No root_component specified" if @root_component.nil?
      raise ArgumentError, "No page_store specified" if @page_store.nil?

      @initial_page = Wee::Page.new(nil, @root_component, nil, nil)   
      @initial_page.snapshot = @initial_page.take_snapshot
    end
  end

  # The main routine where the request is processed.

  def process_request
    if @context.request.page_id.nil?

      # No page_id was specified in the URL. This means that we start with a
      # fresh component and a fresh page_id, then redirect to render itself.

      handle_new_page

    elsif @page = @page_store.fetch(@context.request.page_id, false)

      # A valid page_id was specified and the corresponding page exists.

      handle_existing_page

    else

      # A page_id was specified in the URL, but there's no page for it in the
      # page store. Either the page has timed out, or an invalid page_id was
      # specified. 

      handle_invalid_page

    end
  end

  def handle_new_page
    handle_new_page_view(@context, @initial_page)
  end

  def handle_existing_page
    @page.snapshot.restore if @context.request.page_id != @snapshot_page_id 

    p @context.request.fields if $DEBUG

    if @context.request.render?
      handle_render_phase
    else
      handle_callback_phase
    end
  end

  def handle_invalid_page
    # TODO:: Display an "invalid page or page timed out" message, which
    # forwards to /app/session-id
    raise "Not yet implemented"
  end

  def handle_render_phase
    # No action/inputs were specified -> render page
    #
    # 1. Reset the action/input fields (as they are regenerated in the
    #    rendering process).
    # 2. Render the page (respond).
    # 3. Store the page back into the store

    @page = Wee::Page.new(nil, @root_component, @page.snapshot, Wee::Callbacks.new) # remove all action/input handlers
    respond(@context, @page)                              # render
    @page_store[@context.request.page_id] = @page         # store
  end

  def handle_callback_phase
    # Actions/inputs were specified.
    #
    # We process the request and invoke actions/inputs. Then we generate a
    # new page view. 

    premature_response = @page.process_callbacks(@context.request.fields)

    post_callbacks_hook()

    if premature_response
      # replace existing page with new snapshot
      @page.snapshot = @page.take_snapshot
      @page_store[@context.request.page_id] = @page
      @snapshot_page_id = @context.request.page_id  

      # and send response
      set_response(@context, premature_response) 
    else
      handle_new_page_view(@context)
    end
  end

  def handle_new_page_view(context, page=nil)
    new_page_id = @idgen.next.to_s
    new_page = Wee::Page.new(nil, @root_component, nil, Wee::Callbacks.new)
    if page
      new_page.snapshot = page.snapshot
    else
      new_page.snapshot = new_page.take_snapshot
    end
    @page_store[new_page_id] = new_page
    @snapshot_page_id = new_page_id 
    redirect_url = context.request.build_url(:page_id => new_page_id)
    set_response(context, Wee::RedirectResponse.new(redirect_url))
  end

  def respond(context, page)
    pre_respond_hook
    set_response(context, Wee::GenericResponse.new('text/html', ''))
    rctx = Wee::RenderingContext.new(context, page.callbacks, Wee::HtmlWriter.new(context.response.content))
    page.render(rctx)
  end

  def pre_respond_hook
  end

  def post_callbacks_hook
  end

end
