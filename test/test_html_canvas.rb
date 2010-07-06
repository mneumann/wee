require 'test/unit'
module Wee; end
require 'wee/html_document'
require 'wee/html_brushes'
require 'wee/html_canvas'
require 'wee/callback'
require 'wee/request'
require 'flexmock/test_unit'
#require 'wee/context'

class Test_HtmlCanvas < Test::Unit::TestCase
def new_canvas (doc,cbs = nil,req = nil)
   session=nil
   request=req
  response=nil
 callbacks=cbs
  document=doc
current_component=nil
   c = Wee::HtmlCanvas.new(session,request,response,callbacks,document,current_component)
end
  def test_simple
	
   doc = Wee::HtmlDocument.new
   c = new_canvas(doc)
    c.form.action("foo").with {
      c.table {
        c.table_row.id("myrow").with {
          c.table_data.align_top.with("Hello world")
        }
      }
      c.space
    }
   puts doc.to_s

   assert_equal %[<form method="POST" action="foo"><table><tr id="myrow"><td align="top">Hello world</td></tr></table>&nbsp;</form>], doc.to_s

  end
def test_wrong_brushname
   doc = Wee::HtmlDocument.new
   c = new_canvas(doc)
   begin
    c.form.action("foo").with {
	c.password_field.value "hello"
    }
   fail "expected exception"
   rescue; end

end
def test_mock_callback
   doc = Wee::HtmlDocument.new
   cbs = Wee::Callbacks.new
   req = flexmock(:build_url => "test/")

#      cb = flexmock("callbacks")
#	sensor.should_receive(:"respond_to?").times(1).
#        and_return(10, 12, 14)

	c = new_canvas(doc,cbs,req)
	@callback = false
	c.anchor.callback {@callback = true}.with("hello!")

	puts cbs.inspect.split(" ").join("\n")
	puts doc.to_s
end

end

