#
# Implementation of the Arc Challenge using Wee.
#
# By Michael Neumann (mneumann@ntecs.de)
#
# http://onestepback.org/index.cgi/Tech/Ruby/ArcChallenge.red
#

$LOAD_PATH.unshift "../lib"
require 'rubygems'
require 'wee'

class Wee::IO
  def initialize(component)
    @component = component
  end

  def ask
    @component.call_inline do |r|
      r.form do
        text = nil
        r.text_input.callback {|t| text = t}
        r.submit_button.callback { answer(text) }.value("Enter")
      end
    end 
  end

  def pause(text)
    @component.call_inline {|r| r.anchor.callback { answer }.with(text) }
  end

  def tell(text)
    @component.call_inline {|r| r.text text.to_s }
  end
end

class ArcChallenge < Wee::Task
  def go
    io = Wee::IO.new(self)
    text = io.ask
    io.pause("click here")
    io.tell("You said: #{text}")
  end
end

Wee.runcc(ArcChallenge) if __FILE__ == $0
