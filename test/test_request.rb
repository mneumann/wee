require 'test/unit'
module Wee; end
require 'wee/request'

class Test_Request < Test::Unit::TestCase
  def test_parse
    d = Wee::Request::DELIM
    req = Wee::Request.new('/app', "/app/info#{d}req_handler_id/page_id", nil, nil, nil)
    assert_equal 'info', req.info
    assert_equal 'req_handler_id', req.request_handler_id
    assert_equal 'page_id', req.page_id
  end

  def test_fields
    fields = {
      'a' => 1, 
      'b' => 2,
      'a.x' => 3,
      'a.y' => 4,
    }

    parsed = { 
      'a' => {nil => 1, 'x' => 3, 'y' => 4},
      'b' => 2
    }

    req = Wee::Request.new('/app', "/app", nil, fields, nil)
    assert_equal parsed, req.fields
  end

  def test_build_url
    d = Wee::Request::DELIM
    req = Wee::Request.new('/app', "/app/info#{d}req_handler_id/page_id", nil, nil, nil)

    assert_equal "/app/info#{d}req_handler_id/page_id?c", req.build_url(:callback_id => 'c')

    assert_equal "/app/info#{d}a/b?c", req.build_url(:request_handler_id => 'a', :page_id => 'b', :callback_id => 'c')
    assert_equal "/app/info#{d}req_handler_id/b", req.build_url(:request_handler_id => 'req_handler_id', :page_id => 'b')

    assert_equal "/app/info", req.build_url(:request_handler_id => nil, :page_id => nil)
  end
end
