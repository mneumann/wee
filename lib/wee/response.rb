require 'time'
require 'rack'

module Wee

  class Response < Rack::Response
    alias << write
  end

  class GenericResponse < Response
    EXPIRE_OFFSET = 3600*24*365*20   # 20 years
    EXPIRES_HEADER = 'Expires'.freeze

    def initialize(*args)
      super
      self[EXPIRES_HEADER] ||= (Time.now + EXPIRE_OFFSET).rfc822
    end
  end

  class RedirectResponse < Response
    LOCATION_HEADER = 'Location'.freeze

    def initialize(location)
      super(['<title>302 - Redirect</title><h1>302 - Redirect</h1>',
             '<p>You are being redirected to <a href="', location, '">', 
             location, '</a>'], 302, LOCATION_HEADER => location)
    end
  end

  class RefreshResponse < Response
    def initialize(message, location, seconds=5)
      super([%[<html>
        <head>
          <meta http-equiv="REFRESH" content="#{seconds};URL=#{location}">
          <title>#{message}</title>
        </head>
        <body>
          <h1>#{message}</h1>
          You are being redirected to <a href="#{location}">#{location}</a> 
          in #{seconds} seconds.
        </body>
        </html>]])
    end
  end

  class NotFoundResponse < Response
    def initialize
      super(['<title>404 - Not Found</title><h1>404 - Not Found</h1>'], 404)
    end
  end

  class ErrorResponse < Response
    include Rack::Utils

    def initialize(exception)
      super()
      self << "<html><head><title>Error occured</title></head><body>"
      self << "<p>#{ escape_html(@exception.inspect) }<br/>"
      self << exception.backtrace.map{|s| escape_html(s)}.join("<br/>") 
      self << "</p>"
      self << "</body></html>"
    end
  end

end # module Wee
