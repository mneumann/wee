class Wee::PagelessRequest < Wee::Request

  def build_url(request_handler_id=nil, page_id=nil, callback_id=nil)
    url = "" 
    url << @app_path
    url << ('?' + callback_id) if callback_id
    return url
  end

  def parse_path
    if sid = @cookies.find {|c| c.name == 'SID'}
      @request_handler_id = sid.value
    end
  end
end
