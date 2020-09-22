require 'test/unit'
require 'wee'

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

    assert_equal '<html><body><a href="http://...">link</a></body></html>', doc
  end

  def test_start_end_tag
    w = Wee::HtmlWriter.new(doc='')
    w.start_tag('a', 'href' => '')
    w.end_tag('a')
    assert_equal '<a href=""></a>', doc
  end

  def test_single_tag
    w = Wee::HtmlWriter.new(doc='')
    w.single_tag('a', 'href' => '')
    assert_equal '<a href="" />', doc
  end

end
