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
    attributes.each {|k, v| @port << %[ #{ k }="#{ v }"] }

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

  def valid?
    @tag_stack.empty?
  end

end

if __FILE__ == $0
  doc = ''
  w = Wee::HtmlWriter.new(doc)

  w.start_tag('html')

  w.start_tag('blah')
  w.end_tag('blah')

  w.end_tag('html')
  p w.valid?
  p doc 
end
