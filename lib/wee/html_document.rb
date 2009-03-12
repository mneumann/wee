require 'wee/html_writer'

module Wee

  #
  # Represents a complete HTML document.
  #
  class HtmlDocument < HtmlWriter
    def initialize
      super([])
    end

    def set
      @set ||= {}
    end

    def divert(tag, txt=nil, &block)
      raise ArgumentError if txt and block
      @divert ||= {}

      unless divert = @divert[tag]
        @divert[tag] = divert = []
        @port << divert
      end

      if txt
        divert << txt
      end

      if block
        old_port = @port
        begin
          @port = divert
          block.call
        ensure
          @port = old_port
        end
      end
    end

    def to_s
      @port.join
    end
  end
end
