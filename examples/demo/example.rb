require 'wee'
require_relative 'window'
require_relative 'editable_counter'
require_relative 'messagebox'

class RegexpValidatedInput < Wee::Component

  def initialize(init_value, regexp)
    super()
    @regexp = regexp
    self.value = init_value
    @error = false
  end

  def state(s)
    super
    s.add(self)
  end

  def value
    @value
  end

  def value=(new_value)
    raise unless new_value =~ @regexp
    @input = @value = new_value
  end

  def render(r)
    r.form do
      r.text_input.value(@input).callback {|val| self.input = val }
      r.text %(<div style="color: red">Invalid input</div>) if @error
    end
  end

  def input
    @input
  end

  def input=(str)
    @input = str

    if @input =~ @regexp
      @value = str 
      @error = false
    else
      @error = true
    end
  end

end

class MainPage < Wee::Component
  def initialize
    super()
    @counters = (1..10).map {|i|
      Window.new {|w|
        w.title = "Cnt #{ i }"
        w.pos_x = "200px"
        w.pos_y = "#{i*50}px"
	w << EditableCounter.new(i)
      }
    }

    @val_inp = RegexpValidatedInput.new('Michael Neumann', /^\w+\s+\w+$/)

    @arr = []
    @text = ""

    @list1 = (0..9).to_a
    @selected1 = []
    @list2 = []
    @selected2 = []
  end

  def children
    [@val_inp, *@counters]
  end

  def state(s)
    super
    s.add(@counters)
    state_decoration(s)
    s.add(@arr)
    s.add(@text)

    s.add(@list1)
    s.add(@selected1)
    s.add(@list2)
    s.add(@selected2)
  end

  attr_accessor :text

  def render(r)
    r.page.title("Counter Test").with do 

      r.form do
        r.select_list(@list1).size(10).multiple.selected(@selected1).callback {|choosen| @selected1.replace(choosen)}
        r.submit_button.value('-&gt;').callback { @list2.push(*@selected1); @list1.replace(@list1-@selected1); @selected1.replace([]) } 
        r.submit_button.value('&lt;-').callback { @list1.push(*@selected2); @list2.replace(@list2-@selected2); @selected2.replace([]) } 
        r.select_list(@list2).size(10).multiple.selected(@selected2).callback {|choosen| @selected2.replace(choosen)}
      end

      r.form do

      @counters.each { |cnt|
        r.render(cnt)  
      }

      r.render(@val_inp)

      @arr.each do |a|
        r.text(a)
        r.break
      end

      end

      r.form do
        r.text_input.value(@text).callback{|val| @text = val}
        r.submit_button.callback{add}.value('add')
      end

    end 
  end

  def add
    call Wee::MessageBox.new("Do you really want to add '" + @text + "'?") do |res|
      if res
        call Wee::MessageBox.new("Do you really really really want to add '" + @text + "'?") do |res2| 
          @arr << @text if res2
        end
      end
    end 
  end
end

Wee.run(MainPage) if __FILE__ == $0
