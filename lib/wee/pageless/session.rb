require 'thread'
require 'cgi'

# A session class, which does not have a page-store and as such cannot
# backtrack.

class Wee::PagelessSession < Wee::Session
  attr_accessor :root_component
  undef page_store

  attr_accessor :callbacks
  alias current_callbacks callbacks

  def setup(&block)
    with_session do
      block.call(self) if block
      raise ArgumentError, "No root component specified" if @root_component.nil?
    end
  end

  # The main routine where the request is processed.

  def process_request
    handle_existing_page
  end

  def handle_existing_page
    p @context.request.fields if $DEBUG

    if @context.request.render?
      handle_render_phase
    else
      handle_callback_phase
    end
  end

  def handle_render_phase
    new_callbacks = Wee::CallbackRegistry.new(Wee::SimpleIdGenerator.new)
    respond(@context, new_callbacks)   # render
    self.callbacks = new_callbacks
  end

  def handle_callback_phase
    # Actions/inputs were specified.
    #
    # We process the request and invoke actions/inputs. Then we generate a
    # new page view. 

    callback_stream = Wee::CallbackStream.new(self.callbacks, @context.request.fields) 
    send_response = invoke_callbacks(callback_stream)

    post_callbacks_hook()

    if send_response
      set_response(@context, send_response)    # @context.response = send_response
    else
      handle_new_page_view(@context)
    end
  end

  private

  def handle_new_page_view(context)
    redirect_url = context.request.build_url
    set_response(context, Wee::RedirectResponse.new(redirect_url))
  end

  def set_response(context, response)
    response.cookies << CGI::Cookie.new('SID', self.id)
    response.header.delete('Expire')
    response.header['Pragma'] = 'No-Cache'
    super
  end

end
