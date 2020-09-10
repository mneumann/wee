require 'wee/root_component'

class Wee::HelloWorld < Wee::RootComponent
  def render(r)
    r.text "Hello World from Wee!"
  end
end
