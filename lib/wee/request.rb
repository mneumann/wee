class Wee::Request

  attr_reader :request_handler_id, :page_id, :fields

  def initialize(path, header, fields)
    @path, @header, @fields = path, header, fields
    @app_path, req_path = @path.split('@', 2)
    @request_handler_id, @page_id = req_path.split('/', 2) if req_path
  end

  def application_path
    @app_path
  end

  def build_url(request_handler_id=nil, page_id=nil, callback_id=nil)
    request_handler_id ||= @request_handler_id
    page_id ||= @page_id

    raise ArgumentError if request_handler_id.nil? and not page_id.nil?
    arr = [request_handler_id, page_id].compact

    url = ""
    url << @app_path
    url << ('@' + arr.join('/')) unless arr.empty?
    url << ('?' + callback_id) if callback_id

    return url
  end
end
