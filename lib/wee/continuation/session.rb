require 'timeout'

class Wee::Session
  def initialize(&block)
    Thread.current[:wee_session] = self

    @idgen = Wee::SimpleIdGenerator.new
    @in_queue, @out_queue = SizedQueue.new(1), SizedQueue.new(1)

    block.call(self)

    raise ArgumentError, "No root component specified" if @root_component.nil?
    raise ArgumentError, "No page_store specified" if @page_store.nil?
    
    @initial_snapshot = snapshot()

    start_request_response_loop
    super()
  ensure
    Thread.current[:wee_session] = nil
  end

  # called by application to send the session a request
  def handle_request(context)
    super

    # Send a request to the session. If the session is currently busy
    # processing another request, this will block. 
    @in_queue.push(context)

    # Wait for the response.
    return @out_queue.pop
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
