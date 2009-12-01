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

class Page1 < Wee::Component
  def initialize
    add_decoration(Wee::FormDecoration.new)
    add_decoration(Wee::PageDecoration.new)
  end

  def render(r)
    r.text_input.callback {|text| call Page2.new(text)}
    r.submit_button.value('OK')
  end
end

class Page2 < Wee::Component
  def initialize(text)
    @text = text
  end
  def render(r)
    r.anchor.callback { call Page3.new(@text) }.with('click here')
  end
end

class Page3 < Page2
  def render(r)
    r.text 'You said: '
    r.text @text
    r.break
  end
end

Wee.run(Page1) if __FILE__ == $0
