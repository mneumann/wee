require 'wee'

class RpnCalculator < Wee::Component
  def initialize
    super()
    add_decoration(Wee::FormDecoration.new)

    @number_stack = []
    @input = "" 
  end

  def render
    # the number stack

    r.ul { @number_stack.each {|num| r.li(num)} }

    # the display

    r.text_input.value(@input).readonly

    r.space

    r.submit_button.value("Enter").callback {
      @number_stack << @input.to_f
      @input = "" 
    }

    r.break

    # the number buttons

    (0..9).each {|num|
      r.submit_button.value(num).callback { @input << num.to_s }
    }

    # the decimal point

    r.submit_button.value(".").disabled(@input.include?(".")).callback { 
      @input << "."
    }

    # binary operators

    ['+', '-', '*', '/'].each { |op|
      r.submit_button.value(op).callback {
        unless @input.empty?
          @number_stack << @input.to_f
          @input = ""
        end
        r2, r1 = @number_stack.pop, @number_stack.pop
        @number_stack.push(r1.send(op, r2))
      }
    }

  end
end

if __FILE__ == $0
  require 'wee/adaptors/webrick' 
  require 'wee/utils'

  app = Wee::Utils.app_for { 
    RpnCalculator.new.add_decoration(Wee::PageDecoration.new('RPN Calculator'))
  }

  Wee::WEBrickAdaptor.register('/calc' => app).start 
end
