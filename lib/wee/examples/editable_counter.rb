# NEEDS: FormDecoration

require 'wee/examples/counter'

class Wee::Examples::EditableCounter < Wee::Examples::Counter 

  def initialize(initial_count=0)
    super
    @show_edit_field = false
  end

  def render_count(r)
    if @show_edit_field
      r.text_input.value(@count).size(6).callback {|val| self.count = val}
      r.submit_button.value('S').callback { submit }
    else
      r.anchor.callback { submit }.with(@count)
    end
  end

  def submit
    if @count.to_s !~ /^\d+$/
      call Wee::MessageBox.new("You entered an invalid counter! Please try again!")
      @count = 0
    else
      @show_edit_field = !@show_edit_field
    end
    @count = @count.to_i
  end

end
