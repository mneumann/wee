class Wee::PagelessRequest < Wee::Request
  private

  def pageless?
    true
  end

  def make_request_path(request_handler_id, page_id)
    ""
  end

  def parse_path
    if sid = @cookies.find {|c| c.name == 'SID'}
      @request_handler_id = sid.value
    end

    full_app_path = @path

    if full_app_path == @app_path
      @info = nil
    elsif full_app_path[0, @app_path.size] == @app_path and full_app_path[@app_path.size] == ?/
      @info = full_app_path[@app_path.size+1..-1] 
    else
      raise "dispatched to wrong handler" 
    end
  end
end
