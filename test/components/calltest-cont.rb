class CallTest < Wee::Component
  def msgbox(msg)
    call Wee::MessageBox.new(msg)
  end

  def render
    r.anchor.callback {
      if msgbox('A')
        msgbox('B')
      else
        msgbox('C')
        msgbox('D')
      end
    }.with("show")
  end
end
