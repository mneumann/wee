require 'cgi'

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
  #   p doc        # => '<html><body><a href="http://...">link</a></body></html>'
  #

  class Wee::HtmlWriter
    attr_accessor :port

    def initialize(port)
      @port = port 
    end

    def start_tag(tag, attributes=nil)
      if attributes
        @port << "<#{ tag }"
        attributes.each {|k, v| 
          if v
            @port << %[ #{ k }="#{ v }"] 
          else
            @port << %[ #{ k }] 
          end
        }
        @port << ">"
      else
        @port << "<#{ tag }>"
      end

      self
    end

    def single_tag(tag, attributes=nil)
      if attributes
        @port << "<#{ tag }"
        attributes.each {|k, v| 
          if v
            @port << %[ #{ k }="#{ v }"] 
          else
            @port << %[ #{ k }] 
          end
        }
        @port << " />"
      else
        @port << "<#{ tag } />"
      end

      self
    end

    def end_tag(tag)
      @port << "</#{ tag }>"

      self
    end

    def text(str)
      @port << str.to_s

      self
    end
    alias << text

    def encode_text(str)
      @port << CGI.escapeHTML(str.to_s)

      self
    end
  end

end # module Wee
