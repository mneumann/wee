$LOAD_PATH.unshift << "../lib"
require 'wee'
require 'wee/continuation'

class MessageBox < Wee::Component
  def initialize(text)
    super()
    @text = text 
  end

  def render
    r.break
    r.text(@text)
    r.form do 
      r.submit_button.value('OK').callback(:answer, true)
      r.space
      r.submit_button.value('Cancel').callback(:answer, false)
    end
    r.break
  end
end

class MessageBox2 < Wee::Component
  def initialize(text)
    super()
    @text = text 
  end

  def render
    r.break
    r.text(@text)
    r.form do 
      r.submit_button.value('OK')
      r.space
      r.submit_button.value('Cancel')
    end
    r.break
  end
end

class MainPage < Wee::Component

  def initialize
    super()
    @msgbox = MessageBox2.new("hallllo")
    children << @msgbox
  end

  def click
    if call MessageBox.new('Really quit?')
      call MessageBox.new('You clicked YES')
    else
      call MessageBox.new('You clicked Cancel')
      call MessageBox.new('super')
    end
  end

  def render
    r.page.title("Draw Test").with do 

      r.break
      r.anchor.callback(:click).with('show')
    end 
  end

end

if __FILE__ == $0
  require 'wee/adaptors/webrick' 
  require 'wee/utils'

  app = Wee::Utils.app_for(MainPage)
  Wee::WEBrickAdaptor.register('/app' => app).start 
end
