require 'thread'

# A session class, which does not have a page-store and as such cannot
# backtrack.

class Wee::PagelessSession < Wee::Session
  attr_accessor :root_component
  undef page_store

  attr_accessor :callbacks
  alias current_callbacks callbacks

  def initialize(&block)
    Thread.current[:wee_session] = self

    # to serialize the requests we need a mutex
    @mutex = Mutex.new    

    block.call(self)

    raise ArgumentError, "No root component specified" if @root_component.nil?
    
    super()
  ensure
    Thread.current[:wee_session] = nil
  end

  def process_request
      p @context.request.fields if $DEBUG

      if @context.request.fields.empty?

        # No action/inputs were specified -> render page
        #
        # 1. Reset the action/input fields (as they are regenerated in the
        #    rendering process).
        # 2. Render the page (respond).
        # 3. Store the page back into the store

        new_callbacks = Wee::CallbackRegistry.new(Wee::SimpleIdGenerator.new)
        respond(@context, new_callbacks)                    # render
        self.callbacks = new_callbacks

      else

        # Actions/inputs were specified.
        #
        # We process the request and invoke actions/inputs. Then we generate a
        # new page view. 

        @callback_stream = Wee::CallbackStream.new(self.callbacks, @context.request.fields) 

        if @callback_stream.all_of_type(:action).size > 1 
          raise "Not allowed to specify more than one action callback"
        end

        live_update_response = catch(:wee_live_update) {
          catch(:wee_back_to_session) { invoke_callbacks }
          nil
        }

        if live_update_response
          @context.response = live_update_response
        else
          handle_new_page_view(@context)
        end

      end

  end

  private

  def handle_new_page_view(context)
    redirect_url = context.request.build_url
    set_response(context, Wee::RedirectResponse.new(redirect_url))
  end

  def set_response(context, response)
    # TODO: depends on WEBrick!
    response.cookies << WEBrick::Cookie.new('SID', self.id)
    response.header.delete('Expire')
    response.header['Pragma'] = 'No-Cache'
    super
  end

end
