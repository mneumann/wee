$LOAD_PATH.unshift '../../lib'
require 'wee'

class Wee::MessageBox < Wee::Component
  def initialize(text)
    @text = text
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

class CallTest < Wee::Component
  def msgbox(msg, state=nil)
    if state
      call Wee::MessageBox.new(msg), &method(state)
    else
      call Wee::MessageBox.new(msg), &method(state)
    end
  end

  def state1
    msgbox('A', :state2)
  end

  def state2(res)
    res ? msgbox('B') : msgbox('C', :state3)
  end

  def state3(res)
    msgbox('D')
  end

  def render(r)
    r.anchor.callback { state1 }.with("show")
  end
end

class CallTestCC < Wee::Component
  def msgbox(msg)
    callcc Wee::MessageBox.new(msg)
  end

  def render(r)
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

if __FILE__ == $0
  $LOAD_PATH.unshift '.'
  require 'plotter'
  MemoryPlotter.new(5, Process.pid).run
  ObjectPlotter.new(5, Object, Array, String, Hash, Bignum).run
  ObjectPlotter.new(5, Thread, Continuation, Proc).run

  mode = ARGV[0]
  page_cache_capa = Integer(ARGV[1] || 20)

  puts "mode: #{mode}"
  puts "capa: #{page_cache_capa}"
  
  case mode 
  when 'call'
    Wee.run { Wee::Session.new(CallTest.new, nil, page_cache_capa) } 
  when 'callcc'
    Wee.run { Wee::Session.new(CallTestCC.new, Wee::Session::ThreadSerializer.new, page_cache_capa) }
  else
    raise
  end
end
