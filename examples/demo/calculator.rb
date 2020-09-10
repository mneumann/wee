require_relative 'messagebox'

class Calculator < Wee::Component
  def initialize
    super()
    @number_stack = []
    @input = "" 
  end

  def state(s)
    super
    s.add(@number_stack)
    s.add(@input)
  end

  def render(r)
    r.ul { @number_stack.each {|num| r.li(num) } }

    r.text_input.value(@input).readonly

    r.space

    r.submit_button.value("Enter").callback { enter }
    r.submit_button.value("C").callback { clear }

    r.break

    (0..9).each {|num|
      r.submit_button.value(num.to_s).callback { append(num.to_s) }
    }

    r.submit_button.value(".").disabled(@input.include?(".")).callback { append(".") }

    ['+', '-', '*', '/'].each { |op|
      r.submit_button.value(op).callback { operation(op) }
    }
  end

  protected

  def enter
    @number_stack << @input.to_f
    clear()
  end

  def clear
    @input.replace("")
  end

  def append(str)
    @input << str
  end

  def operation(op)
    enter unless @input.empty?
    if @number_stack.size < 2
      call Wee::MessageBox.new('Stack underflow!')
    else
      r2, r1 = @number_stack.pop, @number_stack.pop
      @number_stack.push(r1.send(op, r2))
    end
  end
end
