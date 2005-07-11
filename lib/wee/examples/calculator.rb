# NEEDS: FormDecoration

class Wee::Examples::Calculator < Wee::Component
  def initialize
    super()

    @number_stack = []
    @input = "" 
  end

  def render
    # the number stack

    r.ul { @number_stack.each {|num| r.li(num)} }

    # the display

    r.text_input.value(@input).readonly

    r.space

    r.submit_button.value("Enter").callback(:enter)

    r.submit_button.value("C").callback(:clear)

    r.break

    # the number buttons

    (0..9).each {|num|
      r.submit_button.value(num).callback(:append, num.to_s)
    }

    # the decimal point

    r.submit_button.value(".").disabled(@input.include?(".")).callback(:append, '.')

    # binary operators

    ['+', '-', '*', '/'].each { |op|
      r.submit_button.value(op).callback(:operation, op)
    }
  end

  def enter
    @number_stack << @input.to_f
    @input = "" 
  end

  def clear
    @input = ""
  end

  def append(str)
    @input << str 
  end

  def operation(op)
    unless @input.empty?
      @number_stack << @input.to_f
      @input = ""
    end
    if @number_stack.size < 2
      call Wee::MessageBox.new('Stack underflow!')
    else
      r2, r1 = @number_stack.pop, @number_stack.pop
      @number_stack.push(r1.send(op, r2))
    end
  end
end
