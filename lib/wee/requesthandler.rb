class Wee::RequestHandler

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


  # Terminates the handler. 

  def teminate
    @running = false
  end

  # Query whether this handler is still alive.

  def alive?
    return false if not @running
    return false if @max_requests and @request_count >= @max_requests

    now = Time.now
    inactivity = now - @last_access 
    lifetime = now - @creation_time

    return false if @expire_after and inactivity > @expire_after 
    return false if @max_lifetime and lifetime > @max_lifetime 
    return true
  end

  # Extend #handle_request in your own subclass.

  def handle_request(context)
    @request_count += 1
    @last_access = Time.now
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
 
  def initialize
    @last_access = @creation_time = Time.now 
    @expire_after = 30*60                  # The default is 30 minutes of inactivity
    @request_count = 0
    @running = true
  end

end
