class CallTest < Wee::Component
  def state1
    call Wee::MessageBox.new('A'), :state2
  end

  def state2(res)
    if res
      call Wee::MessageBox.new('B')
    else
      call Wee::MessageBox.new('C'), :state3
    end
  end

  def state3(res)
    call Wee::MessageBox.new('D')
  end

  def render
    r.anchor.callback(:state1).with("show")
  end
end
