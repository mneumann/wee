require 'thread'

class Wee::AbstractSession < Wee::RequestHandler

  def self.current
    Thread.current[:wee_session] || (raise "Not in session")
  end

  def initialize
    # to serialize the requests we need a mutex
    @mutex = Mutex.new    

    super()
  end

  # Returns the current context.

  def current_context
    @context
  end

  # Called by Wee::Application to send the session a request.

  def handle_request(context)
    with_session { 
      @mutex.synchronize {
        begin
          @context = context
          super
          awake
          process_request
          sleep
        ensure
          @context = nil   # clean up
        end
      }
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

  # The block is run inside a session.

  def with_session
    Thread.current[:wee_session] = self
    yield
  ensure
    Thread.current[:wee_session] = nil
  end

end
