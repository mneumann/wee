require 'time'
require 'rack'

module Wee

  class Response < Rack::Response
    alias << write
  end

  class GenericResponse < Response
    EXPIRE_OFFSET = 3600*24*365*20   # 20 years

    def initialize(*args)
      super
      self['Expires'] ||= (Time.now + EXPIRE_OFFSET).rfc822
    end
  end

  class RedirectResponse < GenericResponse
    def initialize(location)
      super(['<title>302 - Redirect</title><h1>302 - Redirect</h1>',
             '<p>You are being redirected to <a href="', location, '">', 
             location, '</a>'], 302, 'Location' => location)
    end
  end

  class RefreshResponse < GenericResponse
    def initialize(message, location, seconds=10)
      super(%[<html>
        <head>
          <meta http-equiv="REFRESH" content="#{seconds};URL=#{location}">
          <title>#{message}</title>
        </head>
        <body>
          <h1>#{message}</h1>
          You are being redirected to <a href="#{location}">#{location}</a>
        </body>
        </html>])
    end
  end

  class ErrorResponse < Response
    include Rack::Utils

    def initialize(exception)
      super()
      write "<html><head><title>Error occured</title></head><body>"
      write "<p>#{ escape_html(@exception.inspect) }<br/>"
      write exception.backtrace.map{|s| escape_html(s)}.join("<br/>") 
      write "</p>"
      write "</body></html>"
    end
  end

end
