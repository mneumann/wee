require 'time'

class Wee::Response
end

class Wee::GenericResponse < Wee::Response

  DEFAULT_HEADER = { 'Content-Type' => 'text/html' }.freeze
  EXPIRE_OFFSET  = 3600*24*365*20   # 20 years  

  attr_accessor :status, :content
  attr_reader :header

  def initialize(mime_type = 'text/html', content='')
    @status = 200
    @header = DEFAULT_HEADER.dup
    @header['Expires'] = (Time.now + EXPIRE_OFFSET).rfc822
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

class Wee::RedirectResponse < Wee::GenericResponse
  def initialize(location)
    super('text/html', %{<title>302 - Redirect</title><h1>302 - Redirect</h1><p>You are being redirected to <a href="#{location}">#{location}</a>})
    @status = 302
    @header['Location'] = location  
  end
end
