require 'time'
require 'cgi'

class Wee::Response
  DEFAULT_HEADER = {}.freeze

  attr_accessor :status, :content
  attr_reader :header

  def cookies?
    @cookies
  end

  def cookies
    @cookies ||= []   
  end

  def initialize(mime_type = 'text/html', content='')
    @status = 200
    @header = DEFAULT_HEADER.dup
    self.content_type = mime_type
    @content = content 
  end

  def content_type
    @header['Content-Type']
  end

  def content_type=(mime_type)
    @header['Content-Type'] = mime_type
  end

  def <<(str)
    @content << str
  end
end

class Wee::GenericResponse < Wee::Response

  EXPIRE_OFFSET = 3600*24*365*20   # 20 years

  def initialize(mime_type = 'text/html', content='')
    super
    @header['Expires'] = (Time.now + EXPIRE_OFFSET).rfc822
  end

end

class Wee::RedirectResponse < Wee::GenericResponse
  def initialize(location)
    super('text/html', %[<title>302 - Redirect</title><h1>302 - Redirect</h1><p>You are being redirected to <a href="#{location}">#{location}</a>])
    @status = 302
    @header['Location'] = location
  end
end

class Wee::RefreshResponse < Wee::GenericResponse
  def initialize(message, location, seconds=10)
    super('text/html', %[<html>
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

class Wee::ErrorResponse < Wee::Response
  def initialize(exception)
    super('text/html', '')
    @exception = exception
    render(@content)
  end

  def render(c)
    c << "<html><head><title>Error occured</title></head><body>"
    c << "<p>#{ CGI.escapeHTML(@exception.inspect) }<br/>"
    c << @exception.backtrace.map{|s| CGI.escapeHTML(s)}.join("<br/>") 
    c << "</p>"
    c << "</body></html>"
  end
end
