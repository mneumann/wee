class Wee::MessageBox < Wee::Component
  def initialize(text)
    super()
    @text = text 
  end

  def backtrack(state)
    backtrack_decoration(state)
  end

  def render(r)
    r.bold(@text)
    r.form do 
      r.submit_button.value('OK').callback { answer true }
      r.space
      r.submit_button.value('Cancel').callback { answer false }
    end
  end
end
