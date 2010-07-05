require 'test/unit'
module Wee; end
require 'wee/html_document'
require 'wee/html_brushes'
require 'wee/html_canvas'
#require 'wee/context'

class Test_HtmlCanvas < Test::Unit::TestCase
  def test_simple
	
   doc = Wee::HtmlDocument.new
   session=nil
   request=nil
  response=nil
 callbacks=nil
  document=doc
current_component=nil

   c = Wee::HtmlCanvas.new(session,request,response,callbacks,document,current_component)
    c.form.action("foo").with {
      c.table {
        c.table_row.id("myrow").with {
          c.table_data.align_top.with("Hello world")
        }
      }
      c.space
    }

   assert_equal %[<form method="POST" action="foo"><table><tr id="myrow"><td align="top">Hello world</td></tr></table>&nbsp;</form>], doc.to_s
  end

def test_wrong_brushname
   doc = Wee::HtmlDocument.new
   session=nil
   request=nil
  response=nil
 callbacks=nil
  document=doc
current_component=nil

   c = Wee::HtmlCanvas.new(session,request,response,callbacks,document,current_component)
    c.form.action("foo").with {
	c.password_field.value "hello"
    }

end
end

