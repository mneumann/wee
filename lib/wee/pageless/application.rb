class Wee::PagelessApplication < Wee::Application
  def request_handler_expired(context)
    context.response = Wee::RedirectResponse.new(context.request.build_url(
                                                 :request_handler_id => nil,
                                                 :page_id => nil))
    
    # TODO: depends on WEBrick
    cookie = WEBrick::Cookie.new('SID', '')
    cookie.max_age = 0
    context.response.cookies << cookie
  end
end
