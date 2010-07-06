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

    def has_divert?(tag)
      @divert and @divert[tag]
    end

    def define_divert(tag)
      raise ArgumentError if has_divert?(tag)
      @divert ||= {}
      @port << (@divert[tag] = [])
    end

    def divert(tag, txt=nil, &block)
      raise ArgumentError unless has_divert?(tag)
      raise ArgumentError if txt and block

      divert = @divert[tag]

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

#    def to_s
 #     @port.join
  #  end
    public
    alias_method :orig_to_s,:to_s
    def to_s
	#out insert new lines and indentation to make html human-readable
	#start of tag gets new line & increase indent.
	#closetag decrease indent
	s = ""
	indent = ""
	intag = false
	indent_str = "   "
	@port.dup.each{|e|
		if (e =~ /^<\w+$/) then #start of a tag.
			s << indent << e
			indent << indent_str
			intag = true
		elsif (e =~ /^<\/\w+>$/) then #start of a closing tag.
			indent = indent.sub(indent_str,"") #sub only applies once. so removes the first indent_str from indent.
			s << indent << e << "\n"
		elsif e == ">" then #end of tag.
			s << e << "\n"
			intag = false
		elsif intag #attributes of a starting tab.
			s << e
		else
			s << indent << e << "\n"
		end
	}
	s
   end

  end
end
