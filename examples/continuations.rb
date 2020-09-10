require 'wee'
require_relative 'demo/messagebox'

class MainPage < Wee::Component

  def initialize
    super
    add_decoration(Wee::PageDecoration.new("Test"))
  end

  def click
    if callcc Wee::MessageBox.new('Really quit?')
      callcc Wee::MessageBox.new('You clicked YES')
    else
      callcc Wee::MessageBox.new('You clicked Cancel')
      callcc Wee::MessageBox.new('super')
    end
  end

  def render(r)
    r.anchor.callback_method(:click).with('show')
  end

end

Wee.run(MainPage)
