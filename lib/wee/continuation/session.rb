require 'timeout'

class Wee::AbstractSession

  # Called by Wee::Application to send the session a request.

  def handle_request(context)
    super

    # Send a request to the session. If the session is currently busy
    # processing another request, this will block. 
    @in_queue.push(context)

    # Wait for the response.
    return @out_queue.pop
  end
end

class Wee::Session
  def initialize(&block)
    super()
    @in_queue, @out_queue = SizedQueue.new(1), SizedQueue.new(1)
    setup(&block)
    start_request_response_loop
  end

  def start_request_response_loop
    Thread.abort_on_exception = true
    Thread.new {
      Thread.current[:wee_session] = self
      loop {
        @context = nil

        # get a request, check whether this session is alive after every 5
        # seconds.
        while @context.nil?
          begin
            Timeout.timeout(5) {
              @context = @in_queue.pop
            }
          rescue Timeout::Error
            break unless alive?
          end
        end

        # abort thread if no longer alive
        break if not alive?

        raise "invalid request" if @context.nil?

        begin
          awake
          process_request
          sleep
        rescue Exception => exn
          @context.response = Wee::ErrorResponse.new(exn) 
        end
        @out_queue.push(@context)
      }
      p "session loop terminated" if $DEBUG
    }
  end

end
