require 'rack'

module Wee

  #
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
  #   p doc  # => '<html><body><a href="http://...">link</a></body></html>'
  #
  class HtmlWriter

    attr_accessor :port

    def initialize(port=[])
      @port = port
    end

    CLOSING = ">".freeze
    SINGLE_CLOSING = " />".freeze

    def start_tag(tag, attributes=nil, single=false)
      if attributes
        @port << "<#{tag}"
        attributes.each {|k, v| 
          if v
            @port << %[ #{ k }="#{ v }"] 
          else
            @port << %[ #{ k }] 
          end
        }
        @port << (single ? SINGLE_CLOSING : CLOSING)
      else
        @port << (single ? "<#{tag} />" : "<#{tag}>")
      end
    end

    def single_tag(tag, attributes=nil)
      start_tag(tag, attributes, true)
    end

    def end_tag(tag)
      @port << "</#{tag}>"
    end

    def text(str)
      @port << str.to_s
    end

    def encode_text(str)
      @port << Rack::Utils.escape_html(str.to_s)
    end

  end # class HtmlWriter

end # module Wee
