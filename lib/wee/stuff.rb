module Wee
  DefaultRenderer = Wee::HtmlCanvas
  Version = "0.2-dev"
end

class Wee::ErrorPage < Wee::Component
  def initialize(msg)
    @msg = msg
    super()
  end

  def render_content_on(r)
    r << "<html><head><title>Error: #{@msg}</title><head><body>Error: #{@msg}</body></html>"
  end
end

def parse_url(request)
  hash = {}
  request.path_info.split('/').each do |part|
    # we are only interested in "k:v" parts
    next unless part.include?(':')

    k, v = part.split(/:/, 2)
    hash[k] = v
  end
  hash
end
