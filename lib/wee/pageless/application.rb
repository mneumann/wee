require 'cgi'

class Wee::PagelessApplication < Wee::Application
  def request_handler_expired(context)
    context.response = Wee::RedirectResponse.new(context.request.build_url(
                                                 :request_handler_id => nil,
                                                 :page_id => nil))
    
    cookie = CGI::Cookie.new('SID', '')
    cookie.expires = Time.at(0)
    context.response.cookies << cookie
  end
end
