require 'test/unit'
module Wee; end
require 'wee/renderer/html/writer'

class Test_HtmlWriter < Test::Unit::TestCase
  def test_document
    w = Wee::HtmlWriter.new(doc='')
    w.start_tag('html')
    w.start_tag('body')
    w.start_tag('a', 'href' => 'http://...')
    w.text('link')
    w.end_tag('a')
    w.end_tag('body')
    w.end_tag('html')

    assert_equal true, w.valid?
    assert_equal '<html><body><a href="http://...">link</a></body></html>', doc
  end

  def test_merge_start_end_tag
    w = Wee::HtmlWriter.new(doc='')
    w.start_tag('a', 'href' => '')
    w.end_tag('a')
    assert_equal true, w.valid?
    assert_equal '<a href=""/>', doc
  end
end
