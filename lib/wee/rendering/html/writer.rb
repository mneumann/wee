require 'cgi'

# A class used to write out HTML documents easily.
#
# Usage:
#
#   w = Wee::HtmlWriter.new(doc='')
#   w.start_tag('html')
#   w.start_tag('body')
#   w.start_tag('a', 'href' => 'http://...')
#   w.text('link')
#   w.end_tag('a')
#   w.end_tag('body')
#   w.end_tag('html')
#
#   p w.valid?   # => true
#   p doc        # => '<html><body><a href="http://...">link</a></body></html>'
#

class Wee::HtmlWriter
  attr_accessor :port

  def initialize(port)
    @port = port 
    @open_start_tag = false
    @tag_stack = []
  end

  def start_tag(tag, attributes={})
    @port << ">" if @open_start_tag
    @open_start_tag = true
    @tag_stack.push(tag)

    @port << "<#{ tag }"
    attributes.each {|k, v| 
      if v
        @port << %[ #{ k }="#{ v }"] 
      else
        @port << %[ #{ k }] 
      end
    }

    self
  end

  def end_tag(tag)
    raise "unbalanced html" if @tag_stack.pop != tag

    if @open_start_tag
      @port << "/>"
      @open_start_tag = false
    else
      @port << "</#{ tag }>"
    end

    self
  end

  def text(str)
    if @open_start_tag
      @port << ">"
      @open_start_tag = false
    end

    @port << str.to_s

    self
  end
  alias << text

  def encode_text(str)
    text(CGI.escapeHTML(str.to_s))
  end

  def valid?
    @tag_stack.empty?
  end
end
