require 'test/unit'
module Wee; end
require 'wee/request'
require 'rack'

class Test_Request < Test::Unit::TestCase
  def env
#############################

#SEE RACK TEST CODE FOR HOW TO DO THIS PROPERLY.

#############################


{"HTTP_HOST"=>"localhost:2000",
"HTTP_ACCEPT"=>"text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
"SERVER_NAME"=>"localhost",
"rack.url_scheme"=>"http",
"REQUEST_PATH"=>"/",
"HTTP_USER_AGENT"=>"Mozilla/5.0 (X11; U; Linux i686; en-US; rv:1.9.2.6) Gecko/20100628 Ubuntu/10.04 (lucid) Firefox/3.6.6",
"HTTP_KEEP_ALIVE"=>"115",
#"rack.errors"=>#<IO:0xb777b55c>,
"HTTP_ACCEPT_LANGUAGE"=>"en-us,en;q=0.5",
"SERVER_PROTOCOL"=>"HTTP/1.1",
"rack.version"=>[1,1],
"rack.run_once"=>false,
"SERVER_SOFTWARE"=>"Mongrel 1.1.5",
"PATH_INFO"=>"/",
"REMOTE_ADDR"=>"127.0.0.1",
"SCRIPT_NAME"=>"",
"rack.multithread"=>true,
"HTTP_VERSION"=>"HTTP/1.1",
#"HTTP_COOKIE"=>"innate.sid=25bcc7066795b60c5a6eef6e8c07ecf8e77a6bafd233c6c91ac96808a276fc309e795f47bac7265a6f985b54b9fa7bf1e5184f842c8215a45a864a128833c2a0",
"rack.multiprocess"=>false,
#"REQUEST_URI"=>"/?_p=0&_s=Uwp0dIXiB96s4DQiNUqcqg",
"HTTP_ACCEPT_CHARSET"=>"ISO-8859-1,utf-8;q=0.7,*;q=0.7",
"SERVER_PORT"=>"2000",
"REQUEST_METHOD"=>"GET",
"rack.input"=>StringIO.new, #<StringIO:0xb74a07ec>,
#"QUERY_STRING"=>"_p=0&_s=Uwp0dIXiB96s4DQiNUqcqg",##page=0session_id=...
"HTTP_ACCEPT_ENCODING"=>"gzip,deflate",
"HTTP_CONNECTION"=>"keep-alive",
"GATEWAY_INTERFACE"=>"CGI/1.2"}

  end

  def test_parse
    #I think may have been written before Wee used rack.
    #d = Wee::Request::DELIM
    req = Wee::Request.new(env)
    #assert_equal 'info', req.info
    #assert_equal 'req_handler_id', req.request_handler_id
    #assert_equal 'page_id', req.page_id
	
  end

end
