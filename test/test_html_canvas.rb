require 'test/unit'
module Wee; end
require 'wee/renderer/html/writer'
require 'wee/renderer/html/brushes'
require 'wee/renderer/html/canvas'
require 'wee/context'

class Test_HtmlCanvas < Test::Unit::TestCase
  def test_simple
    rctx = Wee::RenderingContext.new
    rctx.document = Wee::HtmlWriter.new(doc='')

    c = Wee::HtmlCanvas.new(rctx)
    c.form.action("foo").with {
      c.table {
        c.table_row.id("myrow").with {
          c.table_data.align_top.with("Hello world")
        }
      }
      c.space
    }

    assert_equal %[<form action="foo" method="POST"><table><tr id="myrow"><td align="top">Hello world</td></tr></table>&nbsp;</form>], doc
  end
end

