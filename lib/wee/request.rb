class Wee::Request

  attr_reader :request_handler_id, :page_id, :fields

  def initialize(app_path, path, headers, fields)
    @app_path, @path, @headers, @fields = app_path, path, headers, fields

    full_app_path, req_path = @path.split('@', 2)
    @request_handler_id = @page_id = nil
    @request_handler_id, @page_id = req_path.split('/', 2) if req_path
  end

  def application_path
    @app_path
  end

  def build_url(request_handler_id=nil, page_id=nil, callback_id=nil)
    raise ArgumentError if request_handler_id.nil? and not page_id.nil?

    arr = [request_handler_id, page_id].compact

    url = "" 
    url << @app_path
    unless arr.empty?
      url << '/' if url[-1,1] != '/'  # /app@ -> /app/@
      url << ('@' + arr.join('/'))
    end
    url << ('?' + callback_id) if callback_id

    return url
  end
end
