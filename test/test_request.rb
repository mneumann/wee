require 'test/unit'
module Wee; end
require 'wee/request'

class Test_Request < Test::Unit::TestCase
  def test_parse
    req = Wee::Request.new('/app/...@req_handler_id/page_id', nil, nil)
    assert_equal 'req_handler_id', req.request_handler_id
    assert_equal 'page_id', req.page_id
    assert_equal '/app/...@a/b?c', req.build_url('a', 'b', 'c')
    assert_equal '/app/...@req_handler_id/b', req.build_url(nil, 'b')
  end
end
