$LOAD_PATH.unshift << "../lib"
require 'wee'
require 'wee/webrick'
require 'wee/utils/cache'


class MessageBox < Wee::Component
  def initialize(text)
    super()
    @text = text 
  end

  def render_content_on(r)
    r.break
    r.text(@text)
    r.form do 
      r.submit_button.value('OK').action(:answer, true)
      r.space
      r.submit_button.value('Cancel').action(:answer, false)
    end
    r.break
  end
end

class MessageBox2 < Wee::Component
  def initialize(text)
    super()
    @text = text 
  end

  def render_content_on(r)
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

  def render_content_on(r)
    r.page.title("Draw Test").with do 

      r.break
      r.anchor.action(:click).with('show')
      r.render @msgbox
    end 
  end

end

class MySession < Wee::Session
  def initialize
    super do
      self.root_component = MainPage.new
      self.page_store = Wee::Utils::LRUCache.new(10) # backtrack up to 10 pages
    end
  end
end

class MyApplication < Wee::Application
  def shutdown
  end
end

if __FILE__ == $0
  File.open('pid', 'w+') {|f| f << $$}
  MyApplication.new {|app|
    app.name = 'Counter'
    app.path = '/app'
    app.session_class = MySession
    app.session_store = Wee::Utils::LRUCache.new(100)
    app.dumpfile = ''
  }.start
end
